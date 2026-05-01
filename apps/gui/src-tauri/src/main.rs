// Prevents additional console window on Windows in release, DO NOT REMOVE!!
#![cfg_attr(not(debug_assertions), windows_subsystem = "windows")]

use std::collections::HashMap;
use std::fs;
use std::process::{Command, Stdio};
use std::io::{BufRead, BufReader, Write};
use serde::Serialize;
use tauri::Manager;
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

// Check if a brew formula or cask is installed directly — no CLI dependency
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

// Check if a dotfile target path exists on disk
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
            run_cli_command
        ])
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
}
