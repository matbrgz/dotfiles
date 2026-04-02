# 🚀 Universal Dotfiles & System Setup (Monorepo)

> **Modern, type-safe, and cross-platform system configuration tool powered by Turborepo.**

## 📂 Project Structure

- **`apps/`**: Final user applications.
  - `cli/`: TypeScript-based command line interface.
  - `gui/`: Tauri-based desktop application.
- **`packages/`**: Specialized internal modules.
  - `core/`: Orchestration and execution logic.
  - `schema/`: Type-safe configurations and manifests.
  - `os-linux/`: Linux & WSL specialized scripts and logic.
  - `os-windows/`: Windows specialized scripts and logic.
  - `os-macos/`: macOS specialized scripts and logic.
  - `configurations/`: System-wide dotfiles and configurations.
  - `registry/`: Central metadata for programs and versions.

## 🛠️ Tech Stack

- **Monorepo**: Yarn Workspaces + Turborepo
- **Language**: TypeScript (Core, CLI, GUI)
- **Execution**: Bash (Linux/macOS), PowerShell (Windows)
- **GUI**: Tauri + Vite

## 🚀 Getting Started

1. Install dependencies:
   ```bash
   yarn install
   ```

2. Run CLI in dev mode:
   ```bash
   yarn turbo dev --filter=cli
   ```

## 📖 Documentation

Check the `docs/` and `specs/` folders for detailed technical documentation.
