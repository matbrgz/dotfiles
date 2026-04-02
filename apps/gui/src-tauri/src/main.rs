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

fn get_registry_path(handle: &tauri::AppHandle) -> Result<PathBuf, String> {
    if let Some(path) = handle.path_resolver().resolve_resource("../../packages/registry") {
        if path.exists() { return Ok(path); }
    }
    let mut path = std::env::current_dir().map_err(|e| e.to_string())?;
    if path.ends_with("src-tauri") { path.pop(); path.pop(); path.pop(); }
    else if path.ends_with("gui") { path.pop(); path.pop(); }
    path.push("packages/registry");
    if path.exists() { Ok(path) } else { Err(format!("Not found at {:?}", path)) }
}

#[tauri::command]
fn get_registry_data(handle: tauri::AppHandle) -> Result<HashMap<String, serde_json::Value>, String> {
    let mut registry_path = get_registry_path(&handle)?;
    registry_path.push("data");
    let mut registry = HashMap::new();
    if let Ok(entries) = fs::read_dir(registry_path) {
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
    let mut dotfiles_path = get_registry_path(&handle)?;
    dotfiles_path.push("data");
    dotfiles_path.push("dotfiles.json");
    if dotfiles_path.exists() {
        let content = fs::read_to_string(dotfiles_path).map_err(|e| e.to_string())?;
        let data: HashMap<String, serde_json::Value> = serde_json::from_str(&content).map_err(|e| e.to_string())?;
        return Ok(data);
    }
    Ok(HashMap::new())
}

#[tauri::command]
fn get_user_settings(handle: tauri::AppHandle) -> Result<serde_json::Value, String> {
    let mut settings_path = get_registry_path(&handle)?;
    settings_path.push("settings.json");
    let content = fs::read_to_string(&settings_path).map_err(|e| e.to_string())?;
    let data: serde_json::Value = serde_json::from_str(&content).map_err(|e| e.to_string())?;
    Ok(data)
}

#[tauri::command]
fn save_user_settings(settings: serde_json::Value, handle: tauri::AppHandle) -> Result<(), String> {
    let mut settings_path = get_registry_path(&handle)?;
    settings_path.push("settings.json");
    let content = serde_json::to_string_pretty(&settings).map_err(|e| e.to_string())?;
    let mut file = fs::File::create(settings_path).map_err(|e| e.to_string())?;
    file.write_all(content.as_bytes()).map_err(|e| e.to_string())?;
    Ok(())
}

#[tauri::command]
async fn check_installation(name: String) -> bool {
    let status = Command::new("yarn")
        .args(["workspace", "@dotfiles/cli", "dev", "check", &name])
        .status();
    
    match status {
        Ok(s) => s.success(),
        Err(_) => false,
    }
}

#[tauri::command]
async fn run_cli_command(command: String, name: Option<String>, window: tauri::Window) -> Result<(), String> {
    let mut args = vec!["workspace", "@dotfiles/cli", "dev", &command];
    if let Some(ref n) = name { args.push(n); }
    let mut child = Command::new("yarn").args(&args).stdout(Stdio::piped()).stderr(Stdio::piped()).spawn().map_err(|e| e.to_string())?;
    let stdout = child.stdout.take().unwrap();
    let stderr = child.stderr.take().unwrap();
    let window_clone = window.clone();
    std::thread::spawn(move || {
        let reader = BufReader::new(stdout);
        for line in reader.lines().flatten() { let _ = window_clone.emit("cli-log", LogEvent { message: line, is_error: false }); }
    });
    let window_clone = window.clone();
    std::thread::spawn(move || {
        let reader = BufReader::new(stderr);
        for line in reader.lines().flatten() { let _ = window_clone.emit("cli-log", LogEvent { message: line, is_error: true }); }
    });
    let status = child.wait().map_err(|e| e.to_string())?;
    if status.success() { let _ = window.emit("cli-finished", true); Ok(()) } 
    else { let _ = window.emit("cli-finished", false); Err("Failed".to_string()) }
}

fn main() {
  tauri::Builder::default()
    .invoke_handler(tauri::generate_handler![
        get_system_info,
        get_registry_data,
        get_dotfiles_data,
        get_user_settings,
        save_user_settings,
        check_installation,
        run_cli_command
    ])
    .run(tauri::generate_context!())
    .expect("error while running tauri application");
}
