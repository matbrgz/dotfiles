# Technical Architecture

This document describes the technical architecture of the `dotfiles` monorepo.

## 1. Monorepo Strategy
We use **Turborepo** for task orchestration and **Yarn Workspaces** for dependency management. This ensures that:
- Each specialized package can be tested and build independently.
- Build and test results are cached to speed up development.
- Dependencies are shared across the repository, reducing the installation size.

## 2. Core Components

### 🧠 `packages/schema`
The "Source of Truth". Defines TypeScript interfaces and Zod schemas for:
- **Program Manifests**: Metadata, categories, and per-platform installation paths.
- **User Settings**: Personal information and system behavior configuration.

### 🧩 `packages/core`
The "Engine". Responsible for:
- **OS Detection**: Identifying Linux, macOS, Windows, and WSL environments.
- **Process Runner**: An abstraction layer that executes Bash or PowerShell scripts and captures logs in real-time.

### 📦 OS-Specialized Packages (`packages/os-*`)
Contain the implementation details for each platform:
- **Scripts**: The actual `.sh` and `.ps1` files.
- **Helpers**: TypeScript libraries for platform-specific tasks (e.g., editing the Windows Registry).

## 3. Applications

### 💻 `apps/cli` (TypeScript)
A powerful command-line interface that:
1. Validates the system environment.
2. Reads the `registry` and `schema`.
3. Triggers installations through the `core` engine.

### 🖼️ `apps/gui` (Tauri)
A modern desktop application with:
- **Tauri Backend (Rust)**: Securely spawns processes and manages system access.
- **Frontend (React/Vue)**: Provides a visual dashboard for package management.

## 4. Execution Flow
1. **User Action**: User selects a program in the CLI or GUI.
2. **Validation**: The app uses `packages/schema` to verify if the program is supported for the current OS.
3. **Execution**: The app calls `packages/core`, which locates the script in the specialized `packages/os-*` folder and executes it.
4. **Feedback**: Real-time logs and exit codes are returned to the user interface.
