// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::collections::HashMap;
use std::fs;
use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader, Write};
use serde::Serialize;
use std::path::PathBuf;

#[derive(Serialize, Clone)]
struct SystemInfo {
    os: String,
    platform: String,
}

#[derive(Serialize, Clone)]
struct LogEvent {
    message: String,
    is_error: bool,
}

#[derive(Serialize, Clone)]
struct DiskCategory {
    id: String,
    label: String,
    icon: String,
    group: String,
    size_bytes: u64,
    item_count: u32,
    safe: bool,
}

#[derive(Serialize, Clone)]
struct CleanEvent {
    id: String,
    freed_bytes: u64,
    error: Option<String>,
    done: bool,
}

#[derive(Serialize, Clone)]
struct LargeFile {
    path: String,
    size_bytes: u64,
}

#[derive(Serialize, Clone)]
struct MemoryInfo {
    total_mb: u64,
    used_mb: u64,
    available_mb: u64,
    inactive_mb: u64,
    wired_mb: u64,
}

#[derive(Serialize, Clone)]
struct ProcInfo {
    pid: u32,
    name: String,
    memory_mb: f64,
    cpu_pct: f64,
}

// ── Shell helpers ──────────────────────────────────────────────────────────────

fn sh(cmd: &str) -> String {
    Command::new("sh")
        .args(["-c", cmd])
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default()
}

fn sh_size(cmd: &str) -> u64 {
    let out = sh(cmd);
    out.split_whitespace()
        .next()
        .and_then(|s| s.parse::<u64>().ok())
        .unwrap_or(0) * 1024
}

fn paths_size(paths: &[&str]) -> (u64, u32) {
    let existing: Vec<&str> = paths
        .iter()
        .copied()
        .filter(|p| std::path::Path::new(p).exists())
        .collect();
    if existing.is_empty() {
        return (0, 0);
    }
    let count = existing.len() as u32;
    let quoted = existing
        .iter()
        .map(|p| format!("\"{}\"", p))
        .collect::<Vec<_>>()
        .join(" ");
    let kb = sh(&format!(
        "du -sk {} 2>/dev/null | awk '{{t+=$1}} END{{print t}}'",
        quoted
    ))
    .trim()
    .parse::<u64>()
    .unwrap_or(0);
    (kb * 1024, count)
}

fn expand(path: &str, home: &str) -> String {
    path.replace('~', home)
}

// ── Tauri commands ─────────────────────────────────────────────────────────────

#[tauri::command]
fn get_system_info() -> SystemInfo {
    SystemInfo {
        os: std::env::consts::OS.to_string(),
        platform: std::env::consts::ARCH.to_string(),
    }
}

#[tauri::command]
fn get_runtime_info() -> HashMap<String, String> {
    let mut info = HashMap::new();
    let node_ver = Command::new("node")
        .arg("--version")
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).trim().to_string())
        .unwrap_or_else(|_| "n/a".to_string());
    info.insert("node".to_string(), if node_ver.is_empty() { "n/a".to_string() } else { node_ver });
    info.insert("tauri".to_string(), format!("v{}", tauri::VERSION));
    info
}

#[tauri::command]
async fn check_brew_package(method: String, package: String) -> bool {
    let args: Vec<&str> = match method.as_str() {
        "brew-cask" => vec!["list", "--cask", &package],
        "brew"      => vec!["list", "--formula", &package],
        "npm"       => return Command::new("npm").args(["list", "-g", "--depth=0", &package]).output().map(|o| o.status.success()).unwrap_or(false),
        _           => return Command::new("which").arg(&package).output().map(|o| o.status.success()).unwrap_or(false),
    };
    Command::new("brew").args(&args).output().map(|o| o.status.success()).unwrap_or(false)
}

#[tauri::command]
fn check_dotfile_exists(target: String) -> bool {
    let home = std::env::var("HOME").unwrap_or_default();
    let path = target.replace('~', &home);
    std::path::Path::new(&path).exists()
}

fn get_repo_root(handle: &tauri::AppHandle) -> Result<PathBuf, String> {
    if let Some(path) = handle.path_resolver().resolve_resource("data") {
        if path.exists() {
            if let Some(parent) = path.parent() {
                return Ok(parent.to_path_buf());
            }
        }
    }
    let mut path = std::env::current_dir().map_err(|e| e.to_string())?;
    loop {
        if path.join("packages/registry").exists() {
            path.push("packages/registry");
            return Ok(path);
        }
        if !path.pop() { break; }
    }
    Err("Could not locate packages/registry".to_string())
}

#[tauri::command]
fn get_registry_data(handle: tauri::AppHandle) -> Result<HashMap<String, serde_json::Value>, String> {
    let mut data_path = get_repo_root(&handle)?;
    data_path.push("data");
    let mut registry = HashMap::new();
    if let Ok(entries) = fs::read_dir(data_path) {
        for entry in entries.flatten() {
            let path = entry.path();
            let file_name = path.file_name().and_then(|s| s.to_str()).unwrap_or("");
            if file_name == "dotfiles.json" { continue; }
            if path.extension().and_then(|s| s.to_str()) == Some("json") {
                if let Ok(content) = fs::read_to_string(&path) {
                    if let Ok(data) = serde_json::from_str::<HashMap<String, serde_json::Value>>(&content) {
                        registry.extend(data);
                    }
                }
            }
        }
    }
    Ok(registry)
}

#[tauri::command]
fn get_dotfiles_data(handle: tauri::AppHandle) -> Result<HashMap<String, serde_json::Value>, String> {
    let mut path = get_repo_root(&handle)?;
    path.push("data");
    path.push("dotfiles.json");
    if path.exists() {
        let content = fs::read_to_string(path).map_err(|e| e.to_string())?;
        let data: HashMap<String, serde_json::Value> = serde_json::from_str(&content).map_err(|e| e.to_string())?;
        return Ok(data);
    }
    Ok(HashMap::new())
}

#[tauri::command]
fn get_user_settings(handle: tauri::AppHandle) -> Result<serde_json::Value, String> {
    let mut path = get_repo_root(&handle)?;
    path.push("settings.json");
    let content = fs::read_to_string(&path).map_err(|e| e.to_string())?;
    let data: serde_json::Value = serde_json::from_str(&content).map_err(|e| e.to_string())?;
    Ok(data)
}

#[tauri::command]
fn save_user_settings(settings: serde_json::Value, handle: tauri::AppHandle) -> Result<(), String> {
    let mut path = get_repo_root(&handle)?;
    path.push("settings.json");
    let content = serde_json::to_string_pretty(&settings).map_err(|e| e.to_string())?;
    let mut file = fs::File::create(path).map_err(|e| e.to_string())?;
    file.write_all(content.as_bytes()).map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
async fn run_cli_command(command: String, name: Option<String>, window: tauri::Window) -> Result<(), String> {
    let mut args = vec!["workspace", "@dotfiles/cli", "dev", &command];
    if let Some(ref n) = name { args.push(n); }

    let mut child = Command::new("yarn")
        .args(&args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(|e| e.to_string())?;

    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();

    let wc = window.clone();
    let stdout_handle = std::thread::spawn(move || {
        for line in BufReader::new(stdout).lines().flatten() {
            let _ = wc.emit("cli-log", LogEvent { message: line, is_error: false });
        }
    });
    let wc = window.clone();
    let stderr_handle = std::thread::spawn(move || {
        for line in BufReader::new(stderr).lines().flatten() {
            let _ = wc.emit("cli-log", LogEvent { message: line, is_error: true });
        }
    });

    let status = child.wait().map_err(|e| e.to_string())?;
    let _ = stdout_handle.join();
    let _ = stderr_handle.join();

    if status.success() {
        let _ = window.emit("cli-finished", true);
        Ok(())
    } else {
        let _ = window.emit("cli-finished", false);
        Err("Command exited with non-zero status".to_string())
    }
}

// ── Disk Cleaner ───────────────────────────────────────────────────────────────

#[tauri::command]
fn scan_disk_usage(window: tauri::Window) -> Vec<DiskCategory> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    let h = |p: &str| expand(p, &home);

    let mut categories: Vec<DiskCategory> = Vec::new();

    // Helper to emit and push
    let emit_cat = |window: &tauri::Window, cats: &mut Vec<DiskCategory>, cat: DiskCategory| {
        let _ = window.emit("scan-category", cat.clone());
        cats.push(cat);
    };

    // ── Development ───────────────────────────────────────────────────────────

    // node_modules
    {
        let dirs_raw = sh(&format!(
            "find {}/dev -maxdepth 6 -name node_modules -type d -prune 2>/dev/null",
            home
        ));
        let dirs: Vec<&str> = dirs_raw.lines().filter(|l| !l.is_empty()).collect();
        let count = dirs.len() as u32;
        let kb = if dirs.is_empty() { 0 } else {
            let quoted = dirs.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(" ");
            sh(&format!(
                "du -sk {} 2>/dev/null | awk '{{t+=$1}} END{{print t}}'",
                quoted
            )).trim().parse::<u64>().unwrap_or(0)
        };
        emit_cat(&window, &mut categories, DiskCategory {
            id: "node_modules".into(), label: "node_modules".into(),
            icon: "📦".into(), group: "Development".into(),
            size_bytes: kb * 1024, item_count: count, safe: true,
        });
    }

    // build_outputs
    {
        let dirs_raw = sh(&format!(
            "find {}/dev -maxdepth 5 -type d \\( -name dist -o -name build -o -name .next -o -name .turbo -o -name .cache -o -name out -o -name .nuxt -o -name .svelte-kit \\) -prune 2>/dev/null",
            home
        ));
        let dirs: Vec<&str> = dirs_raw.lines().filter(|l| !l.is_empty()).collect();
        let count = dirs.len() as u32;
        let kb = if dirs.is_empty() { 0 } else {
            let quoted = dirs.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(" ");
            sh(&format!(
                "du -sk {} 2>/dev/null | awk '{{t+=$1}} END{{print t}}'",
                quoted
            )).trim().parse::<u64>().unwrap_or(0)
        };
        emit_cat(&window, &mut categories, DiskCategory {
            id: "build_outputs".into(), label: "Build outputs".into(),
            icon: "🏗".into(), group: "Development".into(),
            size_bytes: kb * 1024, item_count: count, safe: true,
        });
    }

    // .DS_Store
    {
        let files_raw = sh(&format!(
            "find {}/dev -name .DS_Store 2>/dev/null",
            home
        ));
        let files: Vec<&str> = files_raw.lines().filter(|l| !l.is_empty()).collect();
        let count = files.len() as u32;
        let size_bytes = count as u64 * 6144; // DS_Store files are tiny ~6KB each
        emit_cat(&window, &mut categories, DiskCategory {
            id: "ds_store".into(), label: ".DS_Store files".into(),
            icon: "🫧".into(), group: "Development".into(),
            size_bytes, item_count: count, safe: true,
        });
    }

    // ── Package Caches ────────────────────────────────────────────────────────

    // npm_cache
    {
        let p = h("~/.npm/_cacache");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "npm_cache".into(), label: "npm cache".into(),
            icon: "📦".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // yarn_cache
    {
        let p = h("~/Library/Caches/Yarn");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "yarn_cache".into(), label: "Yarn cache".into(),
            icon: "🧶".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // pnpm_store
    {
        let p = h("~/Library/pnpm/store");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "pnpm_store".into(), label: "pnpm store".into(),
            icon: "⚡".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // pip_cache
    {
        let pip_dir = sh("python3 -m pip cache dir 2>/dev/null").trim().to_string();
        let (size_bytes, item_count) = if pip_dir.is_empty() || !std::path::Path::new(&pip_dir).exists() {
            (0, 0)
        } else {
            paths_size(&[&pip_dir])
        };
        emit_cat(&window, &mut categories, DiskCategory {
            id: "pip_cache".into(), label: "pip cache".into(),
            icon: "🐍".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // cargo_cache
    {
        let p1 = h("~/.cargo/registry/cache");
        let p2 = h("~/.cargo/git/db");
        let (size_bytes, item_count) = paths_size(&[&p1, &p2]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "cargo_cache".into(), label: "Cargo cache".into(),
            icon: "🦀".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // gradle_cache
    {
        let p = h("~/.gradle/caches");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "gradle_cache".into(), label: "Gradle cache".into(),
            icon: "🐘".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // maven_cache
    {
        let p = h("~/.m2/repository");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "maven_cache".into(), label: "Maven cache".into(),
            icon: "☕".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // go_cache
    {
        let go_dir = sh("go env GOCACHE 2>/dev/null").trim().to_string();
        let (size_bytes, item_count) = if go_dir.is_empty() || !std::path::Path::new(&go_dir).exists() {
            (0, 0)
        } else {
            paths_size(&[&go_dir])
        };
        emit_cat(&window, &mut categories, DiskCategory {
            id: "go_cache".into(), label: "Go cache".into(),
            icon: "🐹".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // gem_cache
    {
        let p = h("~/.gem");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "gem_cache".into(), label: "Ruby gems".into(),
            icon: "💎".into(), group: "Package Caches".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // ── macOS ─────────────────────────────────────────────────────────────────

    // brew_cache
    {
        let brew_cache = sh("brew --cache 2>/dev/null").trim().to_string();
        let (size_bytes, item_count) = if brew_cache.is_empty() || !std::path::Path::new(&brew_cache).exists() {
            (0, 0)
        } else {
            paths_size(&[&brew_cache])
        };
        emit_cat(&window, &mut categories, DiskCategory {
            id: "brew_cache".into(), label: "Homebrew cache".into(),
            icon: "🍺".into(), group: "macOS".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // brew_logs
    {
        let p = h("~/Library/Logs/Homebrew");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "brew_logs".into(), label: "Homebrew logs".into(),
            icon: "🍺".into(), group: "macOS".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // xcode_derived
    {
        let p = h("~/Library/Developer/Xcode/DerivedData");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "xcode_derived".into(), label: "Xcode DerivedData".into(),
            icon: "🔨".into(), group: "macOS".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // xcode_archives
    {
        let p = h("~/Library/Developer/Xcode/Archives");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "xcode_archives".into(), label: "Xcode Archives".into(),
            icon: "📦".into(), group: "macOS".into(),
            size_bytes, item_count, safe: false,
        });
    }

    // ios_sims
    {
        let p = h("~/Library/Developer/CoreSimulator/Devices");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "ios_sims".into(), label: "iOS Simulators (unavailable)".into(),
            icon: "📱".into(), group: "macOS".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // lib_caches
    {
        let p = h("~/Library/Caches");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "lib_caches".into(), label: "~/Library/Caches".into(),
            icon: "📂".into(), group: "macOS".into(),
            size_bytes, item_count, safe: false,
        });
    }

    // trash
    {
        let p = h("~/.Trash");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "trash".into(), label: "Trash".into(),
            icon: "🗑".into(), group: "macOS".into(),
            size_bytes, item_count, safe: false,
        });
    }

    // ── AI Tools ──────────────────────────────────────────────────────────────

    // claude_cache
    {
        let p1 = h("~/.claude/cache");
        let p2 = h("~/.claude/paste-cache");
        let p3 = h("~/.claude/shell-snapshots");
        let p4 = h("~/.claude/telemetry");
        let p5 = h("~/.claude/file-history");
        let (size_bytes, item_count) = paths_size(&[&p1, &p2, &p3, &p4, &p5]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "claude_cache".into(), label: "Claude Code cache".into(),
            icon: "🤖".into(), group: "AI Tools".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // codex_cache
    {
        let p1 = h("~/.codex/log");
        let p2 = h("~/.codex/sessions");
        let p3 = h("~/Library/Application Support/Codex");
        let (size_bytes, item_count) = paths_size(&[&p1, &p2, &p3]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "codex_cache".into(), label: "Codex cache".into(),
            icon: "🤖".into(), group: "AI Tools".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // gemini_tmp
    {
        let p = h("~/.gemini/tmp");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "gemini_tmp".into(), label: "Gemini CLI temp".into(),
            icon: "🤖".into(), group: "AI Tools".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // fly_logs
    {
        let p1 = h("~/.fly/agent-logs");
        let p2 = h("~/.fly/logs");
        let (size_bytes, item_count) = paths_size(&[&p1, &p2]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "fly_logs".into(), label: "Fly.io logs".into(),
            icon: "🪰".into(), group: "AI Tools".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // npm_logs
    {
        let p = h("~/.npm/_logs");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "npm_logs".into(), label: "npm logs".into(),
            icon: "📋".into(), group: "AI Tools".into(),
            size_bytes, item_count, safe: true,
        });
    }

    // ── Other ─────────────────────────────────────────────────────────────────

    // downloads
    {
        let p = h("~/Downloads");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "downloads".into(), label: "Downloads folder".into(),
            icon: "📥".into(), group: "Other".into(),
            size_bytes, item_count, safe: false,
        });
    }

    // zsh_sessions
    {
        let p = h("~/.zsh_sessions");
        let (size_bytes, item_count) = paths_size(&[&p]);
        emit_cat(&window, &mut categories, DiskCategory {
            id: "zsh_sessions".into(), label: "zsh sessions".into(),
            icon: "🐚".into(), group: "Other".into(),
            size_bytes, item_count, safe: true,
        });
    }

    categories
}

#[tauri::command]
fn clean_items(ids: Vec<String>, window: tauri::Window) -> Result<(), String> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    let h = |p: &str| expand(p, &home);

    for id in &ids {
        let freed_before = 0u64;
        let error: Option<String> = None;

        let result: Result<(), String> = (|| {
            match id.as_str() {
                "node_modules" => {
                    let dirs_raw = sh(&format!(
                        "find {}/dev -maxdepth 6 -name node_modules -type d -prune 2>/dev/null",
                        home
                    ));
                    for dir in dirs_raw.lines().filter(|l| !l.is_empty()) {
                        sh(&format!("rm -rf \"{}\" 2>/dev/null", dir));
                    }
                }
                "build_outputs" => {
                    let dirs_raw = sh(&format!(
                        "find {}/dev -maxdepth 5 -type d \\( -name dist -o -name build -o -name .next -o -name .turbo -o -name .cache -o -name out -o -name .nuxt -o -name .svelte-kit \\) -prune 2>/dev/null",
                        home
                    ));
                    for dir in dirs_raw.lines().filter(|l| !l.is_empty()) {
                        sh(&format!("rm -rf \"{}\" 2>/dev/null", dir));
                    }
                }
                "ds_store" => {
                    sh(&format!("find {}/dev -name .DS_Store -delete 2>/dev/null", home));
                }
                "npm_cache" => { sh("npm cache clean --force 2>/dev/null"); }
                "yarn_cache" => { sh("yarn cache clean 2>/dev/null"); }
                "pnpm_store" => { sh("pnpm store prune 2>/dev/null"); }
                "pip_cache"  => { sh("python3 -m pip cache purge 2>/dev/null"); }
                "cargo_cache" => {
                    sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.cargo/registry/cache")));
                    sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.cargo/git/db")));
                }
                "gradle_cache" => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.gradle/caches"))); }
                "maven_cache"  => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.m2/repository"))); }
                "gem_cache"    => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.gem"))); }
                "go_cache"     => { sh("go clean -cache -testcache -modcache 2>/dev/null"); }
                "brew_cache"   => { sh("brew cleanup --prune=all 2>/dev/null"); }
                "brew_logs"    => { sh(&format!("rm -rf {}/Library/Logs/Homebrew/* 2>/dev/null", home)); }
                "xcode_derived"  => { sh(&format!("rm -rf {}/Library/Developer/Xcode/DerivedData/* 2>/dev/null", home)); }
                "xcode_archives" => { sh(&format!("rm -rf {}/Library/Developer/Xcode/Archives/* 2>/dev/null", home)); }
                "ios_sims"     => { sh("xcrun simctl delete unavailable 2>/dev/null"); }
                "lib_caches"   => { sh(&format!("rm -rf {}/Library/Caches/* 2>/dev/null", home)); }
                "trash"        => { sh(&format!("rm -rf {}/.Trash/* 2>/dev/null", home)); }
                "claude_cache" => {
                    for p in &["~/.claude/cache", "~/.claude/paste-cache", "~/.claude/shell-snapshots", "~/.claude/telemetry", "~/.claude/file-history"] {
                        sh(&format!("rm -rf {}/* 2>/dev/null", h(p)));
                    }
                }
                "codex_cache" => {
                    for p in &["~/.codex/log", "~/.codex/sessions", "~/Library/Application Support/Codex"] {
                        sh(&format!("rm -rf \"{}\"/* 2>/dev/null", h(p)));
                    }
                }
                "gemini_tmp" => { sh(&format!("rm -rf {}/* 2>/dev/null", h("~/.gemini/tmp"))); }
                "fly_logs"   => {
                    sh(&format!("rm -rf {}/* 2>/dev/null", h("~/.fly/agent-logs")));
                    sh(&format!("rm -rf {}/* 2>/dev/null", h("~/.fly/logs")));
                }
                "npm_logs"     => { sh(&format!("rm -rf {}/* 2>/dev/null", h("~/.npm/_logs"))); }
                "downloads"    => { sh(&format!("rm -rf {}/Downloads/* 2>/dev/null", home)); }
                "zsh_sessions" => { sh(&format!("rm -rf {}/* 2>/dev/null", h("~/.zsh_sessions"))); }
                _ => {}
            }
            Ok(())
        })();

        let err_msg = result.err();
        let _ = window.emit("clean-progress", CleanEvent {
            id: id.clone(),
            freed_bytes: freed_before,
            error: err_msg.or(error),
            done: true,
        });
    }

    Ok(())
}

#[tauri::command]
fn scan_large_files() -> Vec<LargeFile> {
    let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
    let raw = sh(&format!(
        "find {} -not \\( -path '*/node_modules*' -prune \\) -not \\( -path '*/.git*' -prune \\) -size +100M -type f 2>/dev/null | head -20",
        home
    ));
    let mut files: Vec<LargeFile> = Vec::new();
    for line in raw.lines().filter(|l| !l.is_empty()) {
        let size_kb = sh(&format!("du -sk \"{}\" 2>/dev/null", line))
            .split_whitespace().next()
            .and_then(|s| s.parse::<u64>().ok())
            .unwrap_or(0);
        files.push(LargeFile {
            path: line.to_string(),
            size_bytes: size_kb * 1024,
        });
    }
    files.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
    files
}

// ── Memory ─────────────────────────────────────────────────────────────────────

#[tauri::command]
fn get_memory_info() -> MemoryInfo {
    #[cfg(target_os = "macos")]
    {
        let total_bytes: u64 = sh("sysctl -n hw.memsize")
            .trim().parse().unwrap_or(0);
        let total_mb = total_bytes / 1_048_576;

        let page_size: u64 = sh("pagesize").trim().parse().unwrap_or(4096);

        let vm_stat_out = sh("vm_stat");
        let mut free_pages: u64 = 0;
        let mut active_pages: u64 = 0;
        let mut inactive_pages: u64 = 0;
        let mut speculative_pages: u64 = 0;
        let mut wired_pages: u64 = 0;

        for line in vm_stat_out.lines() {
            let parse_pages = |line: &str| -> u64 {
                line.split(':').nth(1)
                    .map(|s| s.trim().trim_end_matches('.'))
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0)
            };
            if line.contains("Pages free:") { free_pages = parse_pages(line); }
            else if line.contains("Pages active:") { active_pages = parse_pages(line); }
            else if line.contains("Pages inactive:") { inactive_pages = parse_pages(line); }
            else if line.contains("Pages speculative:") { speculative_pages = parse_pages(line); }
            else if line.contains("Pages wired down:") { wired_pages = parse_pages(line); }
        }

        let used_mb = (active_pages + wired_pages + speculative_pages) * page_size / 1_048_576;
        let inactive_mb = inactive_pages * page_size / 1_048_576;
        let available_mb = (free_pages + speculative_pages + inactive_pages) * page_size / 1_048_576;
        let wired_mb = wired_pages * page_size / 1_048_576;

        return MemoryInfo { total_mb, used_mb, available_mb, inactive_mb, wired_mb };
    }

    #[cfg(target_os = "linux")]
    {
        let meminfo = fs::read_to_string("/proc/meminfo").unwrap_or_default();
        let mut total_kb: u64 = 0;
        let mut available_kb: u64 = 0;
        let mut free_kb: u64 = 0;

        for line in meminfo.lines() {
            let parse_kb = |line: &str| -> u64 {
                line.split_whitespace().nth(1)
                    .and_then(|s| s.parse().ok())
                    .unwrap_or(0)
            };
            if line.starts_with("MemTotal:") { total_kb = parse_kb(line); }
            else if line.starts_with("MemFree:") { free_kb = parse_kb(line); }
            else if line.starts_with("MemAvailable:") { available_kb = parse_kb(line); }
        }

        let total_mb = total_kb / 1024;
        let available_mb = available_kb / 1024;
        let used_mb = (total_kb - free_kb) / 1024;

        return MemoryInfo { total_mb, used_mb, available_mb, inactive_mb: 0, wired_mb: 0 };
    }

    #[allow(unreachable_code)]
    MemoryInfo { total_mb: 0, used_mb: 0, available_mb: 0, inactive_mb: 0, wired_mb: 0 }
}

#[tauri::command]
fn get_top_processes(limit: u32) -> Vec<ProcInfo> {
    #[cfg(any(target_os = "macos", target_os = "linux"))]
    {
        let raw = sh("ps aux 2>/dev/null");
        let mut procs: Vec<ProcInfo> = Vec::new();

        for line in raw.lines().skip(1) {
            let cols: Vec<&str> = line.split_whitespace().collect();
            if cols.len() < 11 { continue; }
            let pid: u32 = match cols[1].parse() { Ok(v) => v, Err(_) => continue };
            if pid == 0 { continue; }
            let cpu_pct: f64 = cols[2].parse().unwrap_or(0.0);
            let rss_kb: f64 = cols[5].parse().unwrap_or(0.0);
            let memory_mb = rss_kb / 1024.0;
            let cmd = cols[10];
            let name = cmd.split('/').last().unwrap_or(cmd).to_string();
            procs.push(ProcInfo { pid, name, memory_mb, cpu_pct });
        }

        procs.sort_by(|a, b| b.memory_mb.partial_cmp(&a.memory_mb).unwrap_or(std::cmp::Ordering::Equal));
        procs.truncate(limit as usize);
        return procs;
    }

    #[cfg(target_os = "windows")]
    {
        let raw = sh("tasklist /FO CSV /NH 2>/dev/null");
        let mut procs: Vec<ProcInfo> = Vec::new();
        for line in raw.lines() {
            let cols: Vec<&str> = line.splitn(6, ',').collect();
            if cols.len() < 5 { continue; }
            let name = cols[0].trim_matches('"').to_string();
            let pid: u32 = cols[1].trim_matches('"').parse().unwrap_or(0);
            if pid == 0 { continue; }
            let mem_str = cols[4].trim_matches('"').replace(",", "").replace(" K", "");
            let rss_kb: f64 = mem_str.trim().parse().unwrap_or(0.0);
            let memory_mb = rss_kb / 1024.0;
            procs.push(ProcInfo { pid, name, memory_mb, cpu_pct: 0.0 });
        }
        procs.sort_by(|a, b| b.memory_mb.partial_cmp(&a.memory_mb).unwrap_or(std::cmp::Ordering::Equal));
        procs.truncate(limit as usize);
        return procs;
    }

    #[allow(unreachable_code)]
    Vec::new()
}

#[tauri::command]
fn kill_process(pid: u32) -> Result<(), String> {
    #[cfg(any(target_os = "macos", target_os = "linux"))]
    {
        let out = Command::new("kill")
            .args(["-15", &pid.to_string()])
            .output()
            .map_err(|e| e.to_string())?;
        if out.status.success() {
            return Ok(());
        }
        return Err(String::from_utf8_lossy(&out.stderr).to_string());
    }

    #[cfg(target_os = "windows")]
    {
        let out = Command::new("taskkill")
            .args(["/PID", &pid.to_string(), "/F"])
            .output()
            .map_err(|e| e.to_string())?;
        if out.status.success() {
            return Ok(());
        }
        return Err(String::from_utf8_lossy(&out.stderr).to_string());
    }

    #[allow(unreachable_code)]
    Err("Unsupported platform".to_string())
}

fn main() {
    tauri::Builder::default()
        .invoke_handler(tauri::generate_handler![
            get_system_info,
            get_runtime_info,
            check_brew_package,
            check_dotfile_exists,
            get_registry_data,
            get_dotfiles_data,
            get_user_settings,
            save_user_settings,
            run_cli_command,
            scan_disk_usage,
            clean_items,
            scan_large_files,
            get_memory_info,
            get_top_processes,
            kill_process
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
