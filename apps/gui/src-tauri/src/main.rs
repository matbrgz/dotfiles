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
struct DiskItem {
    path: String,
    size_bytes: u64,
    modified_at: Option<u64>,
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
    items: Vec<DiskItem>,
}

#[derive(Serialize, Clone)]
struct ScanProgress {
    current: String,
    step: u32,
    total: u32,
}

#[derive(Serialize, Clone)]
struct CleanEvent {
    id: String,
    freed_bytes: u64,
    error: Option<String>,
    done: bool,
    step: u32,
    total: u32,
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
    elapsed_secs: u64,
    status: String,
    user: String,
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

fn file_mtime(path: &str) -> Option<u64> {
    sh(&format!("stat -f %m \"{}\" 2>/dev/null", path))
        .trim()
        .parse::<u64>()
        .ok()
}

fn paths_size_items(paths: &[&str]) -> (u64, u32, Vec<DiskItem>) {
    let existing: Vec<&str> = paths.iter().copied()
        .filter(|p| std::path::Path::new(p).exists())
        .collect();
    if existing.is_empty() { return (0, 0, vec![]); }
    let quoted = existing.iter()
        .map(|p| format!("\"{}\"", p))
        .collect::<Vec<_>>()
        .join(" ");
    let raw = sh(&format!("nice -n 10 du -sk {} 2>/dev/null", quoted));
    let mut total_kb: u64 = 0;
    let items: Vec<DiskItem> = raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let mut parts = line.splitn(2, '\t');
        let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
        let path = parts.next()?.trim().to_string();
        if path.is_empty() { return None; }
        total_kb += kb;
        Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
    }).collect();
    let count = items.len() as u32;
    (total_kb * 1024, count, items)
}

// ── Git Repos ──────────────────────────────────────────────────────────────────

#[derive(Serialize, Clone)]
struct GitRepoSummary {
    path: String,
    name: String,
    current_branch: String,
    is_dirty: bool,
    ahead: u32,
    behind: u32,
    last_commit_msg: String,
    last_commit_ts: i64,
    stash_count: u32,
}

#[derive(Serialize, Clone)]
struct GitBranch {
    name: String,
    is_remote: bool,
    is_current: bool,
    ahead: Option<u32>,
    behind: Option<u32>,
    last_commit_hash: String,
    last_commit_msg: String,
}

#[derive(Serialize, Clone)]
struct GitCommit {
    short_hash: String,
    full_hash: String,
    message: String,
    author: String,
    ts: i64,
}

#[derive(Serialize, Clone)]
struct GitRemote {
    name: String,
    url: String,
}

#[derive(Serialize, Clone)]
struct GitStash {
    index: u32,
    message: String,
    ts: i64,
}

#[derive(Serialize, Clone)]
struct GitRepoDetail {
    summary: GitRepoSummary,
    branches: Vec<GitBranch>,
    commits: Vec<GitCommit>,
    remotes: Vec<GitRemote>,
    stashes: Vec<GitStash>,
    tags: Vec<String>,
}

fn git(repo: &str, args: &[&str]) -> String {
    Command::new("git")
        .arg("-C").arg(repo)
        .args(args)
        .stderr(Stdio::null())
        .output()
        .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
        .unwrap_or_default()
}

fn repo_summary(path: &str) -> GitRepoSummary {
    let name = std::path::Path::new(path)
        .file_name()
        .and_then(|n| n.to_str())
        .unwrap_or(path)
        .to_string();
    let current_branch = git(path, &["rev-parse", "--abbrev-ref", "HEAD"]).trim().to_string();
    let is_dirty = !git(path, &["status", "--porcelain"]).trim().is_empty();
    let ahead: u32 = git(path, &["rev-list", "--count", "@{u}..HEAD"]).trim().parse().unwrap_or(0);
    let behind: u32 = git(path, &["rev-list", "--count", "HEAD..@{u}"]).trim().parse().unwrap_or(0);
    let last_log = git(path, &["log", "-1", "--format=%s\x1f%ct"]);
    let mut parts = last_log.trim().splitn(2, '\x1f');
    let last_commit_msg = parts.next().unwrap_or("").trim().to_string();
    let last_commit_ts: i64 = parts.next().and_then(|s| s.trim().parse().ok()).unwrap_or(0);
    let stash_count: u32 = git(path, &["stash", "list"]).lines().filter(|l| !l.is_empty()).count() as u32;
    GitRepoSummary { path: path.to_string(), name, current_branch, is_dirty, ahead, behind, last_commit_msg, last_commit_ts, stash_count }
}

#[tauri::command]
fn scan_git_repos(roots: Vec<String>, window: tauri::Window) {
    std::thread::spawn(move || {
        let home = std::env::var("HOME").unwrap_or_default();
        let mut all_paths: Vec<String> = Vec::new();
        for root in &roots {
            let expanded = expand(root, &home);
            let found = Command::new("find")
                .args([expanded.as_str(), "-name", ".git", "-type", "d",
                       "-not", "-path", "*/.git/*", "-maxdepth", "8"])
                .stderr(Stdio::null())
                .output()
                .map(|o| String::from_utf8_lossy(&o.stdout).to_string())
                .unwrap_or_default();
            for line in found.lines() {
                let line = line.trim();
                if line.is_empty() { continue; }
                if let Some(repo_root) = line.strip_suffix("/.git") {
                    all_paths.push(repo_root.to_string());
                }
            }
        }
        all_paths.sort();
        all_paths.dedup();
        let _ = window.emit("git-scan-count", all_paths.len() as u32);
        for path in &all_paths {
            let summary = repo_summary(path);
            let _ = window.emit("git-repo-found", summary);
        }
        let _ = window.emit("git-scan-done", ());
    });
}

#[tauri::command]
fn get_repo_detail(path: String) -> GitRepoDetail {
    let summary = repo_summary(&path);

    // Branches
    let branches_raw = git(&path, &["branch", "-a", "--format=%(refname:short)|%(objectname:short)|%(subject)|%(upstream:track)"]);
    let branches: Vec<GitBranch> = branches_raw.lines().filter(|l| !l.is_empty()).map(|line| {
        let parts: Vec<&str> = line.splitn(4, '|').collect();
        let name = parts.first().copied().unwrap_or("").to_string();
        let last_commit_hash = parts.get(1).copied().unwrap_or("").to_string();
        let last_commit_msg = parts.get(2).copied().unwrap_or("").to_string();
        let track = parts.get(3).copied().unwrap_or("");
        let is_remote = name.contains('/');
        let is_current = name == summary.current_branch;
        let ahead = if track.contains("ahead") {
            track.split("ahead ").nth(1)
                .and_then(|s| s.split(|c: char| !c.is_ascii_digit()).next())
                .and_then(|s| s.parse().ok())
        } else { None };
        let behind = if track.contains("behind") {
            track.split("behind ").nth(1)
                .and_then(|s| s.split(|c: char| !c.is_ascii_digit()).next())
                .and_then(|s| s.parse().ok())
        } else { None };
        GitBranch { name, is_remote, is_current, ahead, behind, last_commit_hash, last_commit_msg }
    }).collect();

    // Commits (last 30) — use \x1f as separator to avoid issues with | in messages
    let commits_raw = git(&path, &["log", "-30", "--format=%h\x1f%H\x1f%s\x1f%an\x1f%ct"]);
    let commits: Vec<GitCommit> = commits_raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let parts: Vec<&str> = line.splitn(5, '\x1f').collect();
        if parts.len() < 5 { return None; }
        Some(GitCommit {
            short_hash: parts[0].to_string(),
            full_hash: parts[1].to_string(),
            message: parts[2].to_string(),
            author: parts[3].to_string(),
            ts: parts[4].trim().parse().unwrap_or(0),
        })
    }).collect();

    // Remotes (deduplicated)
    let remotes_raw = git(&path, &["remote", "-v"]);
    let mut seen: std::collections::HashSet<String> = std::collections::HashSet::new();
    let remotes: Vec<GitRemote> = remotes_raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
        let mut cols = line.split_whitespace();
        let name = cols.next()?.to_string();
        let url = cols.next()?.to_string();
        if !seen.insert(name.clone()) { return None; }
        Some(GitRemote { name, url })
    }).collect();

    // Stashes — use \x1f separator
    let stashes_raw = git(&path, &["stash", "list", "--format=%gd\x1f%s\x1f%ct"]);
    let stashes: Vec<GitStash> = stashes_raw.lines().filter(|l| !l.is_empty()).enumerate().filter_map(|(i, line)| {
        let parts: Vec<&str> = line.splitn(3, '\x1f').collect();
        Some(GitStash {
            index: i as u32,
            message: parts.get(1).copied().unwrap_or("").to_string(),
            ts: parts.get(2).and_then(|s| s.trim().parse().ok()).unwrap_or(0),
        })
    }).collect();

    // Tags (20 most recent)
    let tags_raw = git(&path, &["tag", "--sort=-creatordate"]);
    let tags: Vec<String> = tags_raw.lines().filter(|l| !l.is_empty()).take(20).map(|s| s.to_string()).collect();

    GitRepoDetail { summary, branches, commits, remotes, stashes, tags }
}

#[tauri::command]
fn git_action(path: String, action_type: String, params: serde_json::Value) -> Result<String, String> {
    let run = |args: &[&str]| -> Result<String, String> {
        let out = Command::new("git")
            .arg("-C").arg(&path)
            .args(args)
            .output()
            .map_err(|e| e.to_string())?;
        let stdout = String::from_utf8_lossy(&out.stdout).trim().to_string();
        let stderr = String::from_utf8_lossy(&out.stderr).trim().to_string();
        if out.status.success() { Ok(stdout) } else { Err(if stderr.is_empty() { stdout } else { stderr }) }
    };
    match action_type.as_str() {
        "fetch" => run(&["fetch", params["remote"].as_str().unwrap_or("origin")]),
        "pull"  => run(&["pull", params["remote"].as_str().unwrap_or("origin"), params["branch"].as_str().unwrap_or("")]),
        "push"  => run(&["push", params["remote"].as_str().unwrap_or("origin"), params["branch"].as_str().unwrap_or("")]),
        "checkout"      => run(&["checkout", params["branch"].as_str().ok_or("missing branch")?]),
        "create_branch" => run(&["checkout", "-b", params["name"].as_str().ok_or("missing name")?, params["from"].as_str().unwrap_or("HEAD")]),
        "delete_branch" => {
            let flag = if params["force"].as_bool().unwrap_or(false) { "-D" } else { "-d" };
            run(&["branch", flag, params["name"].as_str().ok_or("missing name")?])
        }
        "stash_push" => {
            if let Some(m) = params["message"].as_str() {
                run(&["stash", "push", "-m", m])
            } else {
                run(&["stash", "push"])
            }
        }
        "stash_pop" => {
            let idx = params["index"].as_u64().unwrap_or(0);
            let ref_str = format!("stash@{{{}}}", idx);
            run(&["stash", "pop", &ref_str])
        }
        "stash_drop" => {
            let idx = params["index"].as_u64().unwrap_or(0);
            let ref_str = format!("stash@{{{}}}", idx);
            run(&["stash", "drop", &ref_str])
        }
        "open_terminal" => {
            #[cfg(target_os = "macos")]
            let _ = Command::new("open").args(["-a", "Terminal", &path]).spawn();
            #[cfg(target_os = "linux")]
            { let _ = Command::new(std::env::var("TERMINAL").unwrap_or_else(|_| "xterm".to_string())).arg(&path).spawn(); }
            #[cfg(target_os = "windows")]
            let _ = Command::new("cmd").args(["/c", "start", "cmd", "/k", &format!("cd /d {}", path)]).spawn();
            Ok("opened".into())
        }
        "open_vscode" => {
            let _ = Command::new("code").arg(&path).spawn();
            Ok("opened".into())
        }
        _ => Err(format!("unknown action: {}", action_type))
    }
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

fn emit_cat(window: &tauri::Window, cat: DiskCategory) {
    let _ = window.emit("scan-category", cat);
}

fn dev_dir(home: &str) -> Option<String> {
    let dev = format!("{}/dev", home);
    if std::path::Path::new(&dev).exists() { Some(dev) } else { None }
}

#[tauri::command]
fn scan_disk_usage(window: tauri::Window) {
    std::thread::spawn(move || {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
        let h = |p: &str| expand(p, &home);
        let mut step: u32 = 0;
        let total: u32 = 26;

        macro_rules! progress {
            ($label:expr) => { step += 1; let _ = window.emit("scan-progress", ScanProgress { current: format!("Scanning {}...", $label), step, total }); };
        }

        // ── Development ──────────────────────────────────────────────────────

        progress!("node_modules");
        {
            let (size_bytes, item_count, mut items) = if let Some(dev) = dev_dir(&home) {
                let dirs_raw = sh(&format!("find {} -maxdepth 6 -name node_modules -type d -prune 2>/dev/null", dev));
                let dirs: Vec<&str> = dirs_raw.lines().filter(|l| !l.is_empty()).collect();
                if dirs.is_empty() { (0, 0, vec![]) } else {
                    let quoted = dirs.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(" ");
                    let raw = sh(&format!("nice -n 10 du -sk {} 2>/dev/null", quoted));
                    let mut total_kb: u64 = 0;
                    let mut items: Vec<DiskItem> = raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
                        let mut parts = line.splitn(2, '\t');
                        let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
                        let path = parts.next()?.trim().to_string();
                        if path.is_empty() { return None; }
                        total_kb += kb;
                        Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
                    }).collect();
                    items.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
                    (total_kb * 1024, items.len() as u32, items)
                }
            } else { (0, 0, vec![]) };
            items.truncate(20);
            let _ = window.emit("scan-category", DiskCategory { id: "node_modules".into(), label: "node_modules".into(), icon: "📦".into(), group: "Development".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("build outputs");
        {
            let (size_bytes, item_count, mut items) = if let Some(dev) = dev_dir(&home) {
                let dirs_raw = sh(&format!("find {} -maxdepth 5 -type d \\( -name dist -o -name build -o -name .next -o -name .turbo -o -name .cache -o -name out -o -name .nuxt -o -name .svelte-kit \\) -prune 2>/dev/null", dev));
                let dirs: Vec<&str> = dirs_raw.lines().filter(|l| !l.is_empty()).collect();
                if dirs.is_empty() { (0, 0, vec![]) } else {
                    let quoted = dirs.iter().map(|p| format!("\"{}\"", p)).collect::<Vec<_>>().join(" ");
                    let raw = sh(&format!("nice -n 10 du -sk {} 2>/dev/null", quoted));
                    let mut total_kb: u64 = 0;
                    let mut items: Vec<DiskItem> = raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
                        let mut parts = line.splitn(2, '\t');
                        let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
                        let path = parts.next()?.trim().to_string();
                        if path.is_empty() { return None; }
                        total_kb += kb;
                        Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
                    }).collect();
                    items.sort_by(|a, b| b.size_bytes.cmp(&a.size_bytes));
                    (total_kb * 1024, items.len() as u32, items)
                }
            } else { (0, 0, vec![]) };
            items.truncate(20);
            let _ = window.emit("scan-category", DiskCategory { id: "build_outputs".into(), label: "Build outputs".into(), icon: "🏗".into(), group: "Development".into(), size_bytes, item_count, safe: true, items });
        }

        progress!(".DS_Store files");
        {
            let (size_bytes, item_count, items) = if let Some(dev) = dev_dir(&home) {
                let files_raw = sh(&format!("find {} -name .DS_Store 2>/dev/null", dev));
                let files: Vec<&str> = files_raw.lines().filter(|l| !l.is_empty()).collect();
                let count = files.len() as u32;
                let items: Vec<DiskItem> = files.iter().take(20).map(|f| DiskItem { path: f.to_string(), size_bytes: 6144, modified_at: file_mtime(f) }).collect();
                (count as u64 * 6144, count, items)
            } else { (0, 0, vec![]) };
            let _ = window.emit("scan-category", DiskCategory { id: "ds_store".into(), label: ".DS_Store files".into(), icon: "🫧".into(), group: "Development".into(), size_bytes, item_count, safe: true, items });
        }

        // ── Package Caches ───────────────────────────────────────────────────

        progress!("npm cache");
        { let p = h("~/.npm/_cacache"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "npm_cache".into(), label: "npm cache".into(), icon: "📦".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Yarn cache");
        { let p = h("~/Library/Caches/Yarn"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "yarn_cache".into(), label: "Yarn cache".into(), icon: "🧶".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("pnpm store");
        { let p = h("~/Library/pnpm/store"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "pnpm_store".into(), label: "pnpm store".into(), icon: "⚡".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("pip cache");
        {
            let pip_dir = sh("python3 -m pip cache dir 2>/dev/null").trim().to_string();
            let (size_bytes, item_count, items) = if pip_dir.is_empty() || !std::path::Path::new(&pip_dir).exists() { (0, 0, vec![]) } else { paths_size_items(&[&pip_dir]) };
            let _ = window.emit("scan-category", DiskCategory { id: "pip_cache".into(), label: "pip cache".into(), icon: "🐍".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("Cargo cache");
        { let p1 = h("~/.cargo/registry/cache"); let p2 = h("~/.cargo/git/db"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2]); let _ = window.emit("scan-category", DiskCategory { id: "cargo_cache".into(), label: "Cargo cache".into(), icon: "🦀".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Gradle cache");
        { let p = h("~/.gradle/caches"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "gradle_cache".into(), label: "Gradle cache".into(), icon: "🐘".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Maven cache");
        { let p = h("~/.m2/repository"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "maven_cache".into(), label: "Maven cache".into(), icon: "☕".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Go cache");
        {
            let go_dir = sh("go env GOCACHE 2>/dev/null").trim().to_string();
            let (size_bytes, item_count, items) = if go_dir.is_empty() || !std::path::Path::new(&go_dir).exists() { (0, 0, vec![]) } else { paths_size_items(&[&go_dir]) };
            let _ = window.emit("scan-category", DiskCategory { id: "go_cache".into(), label: "Go cache".into(), icon: "🐹".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("Ruby gems");
        { let p = h("~/.gem"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "gem_cache".into(), label: "Ruby gems".into(), icon: "💎".into(), group: "Package Caches".into(), size_bytes, item_count, safe: true, items }); }

        // ── macOS ─────────────────────────────────────────────────────────────

        progress!("Homebrew cache");
        {
            let brew_cache = sh("brew --cache 2>/dev/null").trim().to_string();
            let (size_bytes, item_count, items) = if brew_cache.is_empty() || !std::path::Path::new(&brew_cache).exists() { (0, 0, vec![]) } else { paths_size_items(&[&brew_cache]) };
            let _ = window.emit("scan-category", DiskCategory { id: "brew_cache".into(), label: "Homebrew cache".into(), icon: "🍺".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items });
        }

        progress!("Homebrew logs");
        { let p = h("~/Library/Logs/Homebrew"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "brew_logs".into(), label: "Homebrew logs".into(), icon: "🍺".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Xcode DerivedData");
        { let p = h("~/Library/Developer/Xcode/DerivedData"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "xcode_derived".into(), label: "Xcode DerivedData".into(), icon: "🔨".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Xcode Archives");
        { let p = h("~/Library/Developer/Xcode/Archives"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "xcode_archives".into(), label: "Xcode Archives".into(), icon: "📦".into(), group: "macOS".into(), size_bytes, item_count, safe: false, items }); }

        progress!("iOS Simulators");
        { let p = h("~/Library/Developer/CoreSimulator/Devices"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "ios_sims".into(), label: "iOS Simulators (unavailable)".into(), icon: "📱".into(), group: "macOS".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Library/Caches");
        {
            let p = h("~/Library/Caches");
            let (size_bytes, item_count, _) = paths_size_items(&[&p]);
            let items: Vec<DiskItem> = if std::path::Path::new(&p).exists() {
                let raw = sh(&format!("nice -n 10 find \"{}\" -maxdepth 1 -mindepth 1 -exec du -sk {{}} + 2>/dev/null | sort -rn | head -20", p));
                raw.lines().filter(|l| !l.is_empty()).filter_map(|line| {
                    let mut parts = line.splitn(2, '\t');
                    let kb = parts.next().and_then(|s| s.trim().parse::<u64>().ok()).unwrap_or(0);
                    let path = parts.next()?.trim().to_string();
                    if path.is_empty() { return None; }
                    Some(DiskItem { path: path.clone(), size_bytes: kb * 1024, modified_at: file_mtime(&path) })
                }).collect()
            } else { vec![] };
            let _ = window.emit("scan-category", DiskCategory { id: "lib_caches".into(), label: "~/Library/Caches".into(), icon: "📂".into(), group: "macOS".into(), size_bytes, item_count, safe: false, items });
        }

        progress!("Trash");
        { let p = h("~/.Trash"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "trash".into(), label: "Trash".into(), icon: "🗑".into(), group: "macOS".into(), size_bytes, item_count, safe: false, items }); }

        // ── AI Tools ─────────────────────────────────────────────────────────

        progress!("Claude Code cache");
        { let p1 = h("~/.claude/cache"); let p2 = h("~/.claude/paste-cache"); let p3 = h("~/.claude/shell-snapshots"); let p4 = h("~/.claude/telemetry"); let p5 = h("~/.claude/file-history"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2, &p3, &p4, &p5]); let _ = window.emit("scan-category", DiskCategory { id: "claude_cache".into(), label: "Claude Code cache".into(), icon: "🤖".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Codex cache");
        { let p1 = h("~/.codex/log"); let p2 = h("~/.codex/sessions"); let p3 = h("~/Library/Application Support/Codex"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2, &p3]); let _ = window.emit("scan-category", DiskCategory { id: "codex_cache".into(), label: "Codex cache".into(), icon: "🤖".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Gemini CLI temp");
        { let p = h("~/.gemini/tmp"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "gemini_tmp".into(), label: "Gemini CLI temp".into(), icon: "🤖".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("Fly.io logs");
        { let p1 = h("~/.fly/agent-logs"); let p2 = h("~/.fly/logs"); let (size_bytes, item_count, items) = paths_size_items(&[&p1, &p2]); let _ = window.emit("scan-category", DiskCategory { id: "fly_logs".into(), label: "Fly.io logs".into(), icon: "🪰".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        progress!("npm logs");
        { let p = h("~/.npm/_logs"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "npm_logs".into(), label: "npm logs".into(), icon: "📋".into(), group: "AI Tools".into(), size_bytes, item_count, safe: true, items }); }

        // ── Other ─────────────────────────────────────────────────────────────

        progress!("Downloads folder");
        { let p = h("~/Downloads"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "downloads".into(), label: "Downloads folder".into(), icon: "📥".into(), group: "Other".into(), size_bytes, item_count, safe: false, items }); }

        progress!("zsh sessions");
        { let p = h("~/.zsh_sessions"); let (size_bytes, item_count, items) = paths_size_items(&[&p]); let _ = window.emit("scan-category", DiskCategory { id: "zsh_sessions".into(), label: "zsh sessions".into(), icon: "🐚".into(), group: "Other".into(), size_bytes, item_count, safe: true, items }); }

        let _ = window.emit("scan-done", ());
    });
}

#[tauri::command]
fn clean_items(ids: Vec<String>, window: tauri::Window) {
    std::thread::spawn(move || {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
        let h = |p: &str| expand(p, &home);

        let total = ids.len() as u32;
        for (step, id) in ids.iter().enumerate() {
            // Notify UI that this category is starting
            let _ = window.emit("clean-progress", CleanEvent {
                id: id.clone(),
                freed_bytes: 0,
                error: None,
                done: false,
                step: (step + 1) as u32,
                total,
            });

            let result: Result<(), String> = (|| {
                match id.as_str() {
                    "node_modules" => {
                        if let Some(dev) = dev_dir(&home) {
                            let dirs_raw = sh(&format!(
                                "find {} -maxdepth 6 -name node_modules -type d -prune 2>/dev/null",
                                dev
                            ));
                            for dir in dirs_raw.lines().filter(|l| !l.is_empty()) {
                                sh(&format!("rm -rf \"{}\" 2>/dev/null", dir));
                            }
                        }
                    }
                    "build_outputs" => {
                        if let Some(dev) = dev_dir(&home) {
                            let dirs_raw = sh(&format!(
                                "find {} -maxdepth 5 -type d \\( -name dist -o -name build -o -name .next -o -name .turbo -o -name .cache -o -name out -o -name .nuxt -o -name .svelte-kit \\) -prune 2>/dev/null",
                                dev
                            ));
                            for dir in dirs_raw.lines().filter(|l| !l.is_empty()) {
                                sh(&format!("rm -rf \"{}\" 2>/dev/null", dir));
                            }
                        }
                    }
                    "ds_store" => {
                        if let Some(dev) = dev_dir(&home) {
                            sh(&format!("find {} -name .DS_Store -delete 2>/dev/null", dev));
                        }
                    }
                "npm_cache"  => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.npm/_cacache"))); }
                "yarn_cache" => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/Library/Caches/Yarn"))); }
                "pnpm_store" => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/Library/pnpm/store"))); }
                "pip_cache"  => {
                    let pip_dir = sh("python3 -m pip cache dir 2>/dev/null").trim().to_string();
                    if !pip_dir.is_empty() { sh(&format!("rm -rf \"{}\" 2>/dev/null", pip_dir)); }
                }
                "cargo_cache" => {
                    sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.cargo/registry/cache")));
                    sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.cargo/git/db")));
                }
                "gradle_cache" => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.gradle/caches"))); }
                "maven_cache"  => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.m2/repository"))); }
                "gem_cache"    => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.gem"))); }
                "go_cache"     => {
                    let go_dir = sh("go env GOCACHE 2>/dev/null").trim().to_string();
                    if !go_dir.is_empty() { sh(&format!("rm -rf \"{}\" 2>/dev/null", go_dir)); }
                }
                "brew_cache"   => {
                    let brew_cache = sh("brew --cache 2>/dev/null").trim().to_string();
                    if !brew_cache.is_empty() { sh(&format!("rm -rf \"{}\" 2>/dev/null", brew_cache)); }
                }
                "brew_logs"    => { sh(&format!("rm -rf \"{}/Library/Logs/Homebrew\" 2>/dev/null", home)); }
                "xcode_derived"  => { sh(&format!("rm -rf \"{}/Library/Developer/Xcode/DerivedData\" 2>/dev/null", home)); }
                "xcode_archives" => { sh(&format!("rm -rf \"{}/Library/Developer/Xcode/Archives\" 2>/dev/null", home)); }
                "ios_sims"     => { sh("xcrun simctl delete unavailable 2>/dev/null"); }
                "lib_caches"   => { sh(&format!("rm -rf \"{}/Library/Caches\" 2>/dev/null", home)); }
                "trash"        => { sh(&format!("rm -rf \"{}/.Trash\" 2>/dev/null", home)); }
                "claude_cache" => {
                    for p in &["~/.claude/cache", "~/.claude/paste-cache", "~/.claude/shell-snapshots", "~/.claude/telemetry", "~/.claude/file-history"] {
                        sh(&format!("rm -rf \"{}\" 2>/dev/null", h(p)));
                    }
                }
                "codex_cache" => {
                    for p in &["~/.codex/log", "~/.codex/sessions"] {
                        sh(&format!("rm -rf \"{}\" 2>/dev/null", h(p)));
                    }
                    sh(&format!("rm -rf \"{}/Library/Application Support/Codex\" 2>/dev/null", home));
                }
                "gemini_tmp" => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.gemini/tmp"))); }
                "fly_logs"   => {
                    sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.fly/agent-logs")));
                    sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.fly/logs")));
                }
                "npm_logs"     => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.npm/_logs"))); }
                "downloads"    => { sh(&format!("rm -rf \"{}/Downloads\" 2>/dev/null", home)); }
                "zsh_sessions" => { sh(&format!("rm -rf \"{}\" 2>/dev/null", h("~/.zsh_sessions"))); }
                _ => {}
                }
                Ok(())
            })();

            let _ = window.emit("clean-progress", CleanEvent {
                id: id.clone(),
                freed_bytes: 0,
                error: result.err(),
                done: true,
                step: (step + 1) as u32,
                total,
            });
        }
        let _ = window.emit("clean-done", ());
    }); // end thread::spawn
}

#[tauri::command]
fn scan_large_files(window: tauri::Window) {
    std::thread::spawn(move || {
        let home = std::env::var("HOME").unwrap_or_else(|_| "/tmp".to_string());
        // Only scan common directories, not the entire home (too slow)
        let search_dirs = [
            format!("{}/Downloads", home),
            format!("{}/Documents", home),
            format!("{}/Desktop", home),
            format!("{}/Movies", home),
            format!("{}/dev", home),
        ];
        let existing: Vec<String> = search_dirs.into_iter()
            .filter(|d| std::path::Path::new(d).exists())
            .collect();

        if existing.is_empty() {
            let _ = window.emit("large-files-done", Vec::<LargeFile>::new());
            return;
        }

        let dirs_arg = existing.iter()
            .map(|d| format!("\"{}\"", d))
            .collect::<Vec<_>>()
            .join(" ");

        let raw = sh(&format!(
            "find {} -not \\( -path '*/node_modules*' -prune \\) -not \\( -path '*/.git*' -prune \\) -not \\( -path '*/Library/Caches*' -prune \\) -size +100M -type f 2>/dev/null | head -30",
            dirs_arg
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
        let _ = window.emit("large-files-done", files);
    }); // end thread::spawn
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
        // pid, %cpu, rss(KB), comm(basename), stat, etimes(seconds), user
        let raw = sh("ps ax -o pid=,pcpu=,rss=,comm=,stat=,etimes=,user= 2>/dev/null");
        let mut procs: Vec<ProcInfo> = Vec::new();

        for line in raw.lines() {
            let cols: Vec<&str> = line.split_whitespace().collect();
            if cols.len() < 7 { continue; }
            let pid: u32 = match cols[0].parse() { Ok(v) => v, Err(_) => continue };
            if pid == 0 { continue; }
            let cpu_pct: f64 = cols[1].parse().unwrap_or(0.0);
            let rss_kb: f64 = cols[2].parse().unwrap_or(0.0);
            let memory_mb = rss_kb / 1024.0;
            let name = cols[3].split('/').last().unwrap_or(cols[3]).to_string();
            let status = cols[4].to_string();
            let elapsed_secs: u64 = cols[5].parse().unwrap_or(0);
            let user = cols[6].to_string();
            procs.push(ProcInfo { pid, name, memory_mb, cpu_pct, elapsed_secs, status, user });
        }

        // Return all processes (frontend filters/sorts)
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
            procs.push(ProcInfo { pid, name, memory_mb, cpu_pct: 0.0, elapsed_secs: 0, status: "S".into(), user: "unknown".into() });
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
            kill_process,
            scan_git_repos,
            get_repo_detail,
            git_action
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
