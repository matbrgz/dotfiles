#!/bin/bash

# =============================================================================
# DOTFILES UTILITY LIBRARY
# =============================================================================
# Author: matbrgz
# Description: Core utility functions for system detection and package management
# =============================================================================

# Global variables
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SETTINGS_FILE="$PROJECT_ROOT/settings.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    if [[ "${DEBUG_MODE:-false}" == "true" ]]; then
        echo -e "${PURPLE}[DEBUG]${NC} $1"
    fi
}

log_step() {
    echo -e "${CYAN}[STEP]${NC} $1"
}

# =============================================================================
# SYSTEM DETECTION FUNCTIONS
# =============================================================================

detect_os() {
    local os_type=""
    
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if grep -q Microsoft /proc/version 2>/dev/null; then
            os_type="wsl"
        else
            os_type="linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        os_type="macos"
    elif [[ "$OSTYPE" == "cygwin" ]] || [[ "$OSTYPE" == "msys" ]]; then
        os_type="windows"
    else
        os_type="unknown"
    fi
    
    echo "$os_type"
}

detect_distro() {
    local distro=""
    
    if [[ -f /etc/os-release ]]; then
        distro=$(grep "^ID=" /etc/os-release | cut -d'=' -f2 | tr -d '"')
    elif [[ -f /etc/lsb-release ]]; then
        distro=$(grep "DISTRIB_ID" /etc/lsb-release | cut -d'=' -f2 | tr -d '"')
    elif command -v lsb_release >/dev/null 2>&1; then
        distro=$(lsb_release -si | tr '[:upper:]' '[:lower:]')
    else
        distro="unknown"
    fi
    
    echo "$distro"
}

detect_package_manager() {
    local pm=""
    
    # Check for package managers in order of preference
    if command -v yay >/dev/null 2>&1; then
        pm="yay"
    elif command -v pacman >/dev/null 2>&1; then
        pm="pacman"
    elif command -v apt >/dev/null 2>&1; then
        pm="apt"
    elif command -v dnf >/dev/null 2>&1; then
        pm="dnf"
    elif command -v zypper >/dev/null 2>&1; then
        pm="zypper"
    elif command -v brew >/dev/null 2>&1; then
        pm="brew"
    elif command -v snap >/dev/null 2>&1; then
        pm="snap"
    elif command -v flatpak >/dev/null 2>&1; then
        pm="flatpak"
    else
        pm="unknown"
    fi
    
    echo "$pm"
}

get_system_info() {
    local os_type distro package_manager
    
    os_type=$(detect_os)
    distro=$(detect_distro)
    package_manager=$(detect_package_manager)
    
    cat << EOF
{
    "os": "$os_type",
    "distro": "$distro",
    "package_manager": "$package_manager",
    "kernel": "$(uname -r)",
    "architecture": "$(uname -m)",
    "hostname": "$(hostname)"
}
EOF
}

# =============================================================================
# PACKAGE MANAGEMENT FUNCTIONS
# =============================================================================

update_package_manager() {
    local pm="$1"
    
    log_step "Updating package manager: $pm"
    
    case "$pm" in
        "apt")
            sudo apt update && sudo apt upgrade -y
            ;;
        "pacman")
            sudo pacman -Syu --noconfirm
            ;;
        "yay")
            yay -Syu --noconfirm
            ;;
        "dnf")
            sudo dnf update -y
            ;;
        "zypper")
            sudo zypper update -y
            ;;
        "brew")
            brew update && brew upgrade
            ;;
        "snap")
            sudo snap refresh
            ;;
        "flatpak")
            flatpak update -y
            ;;
        *)
            log_warning "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

install_package() {
    local pm="$1"
    local package="$2"
    
    log_step "Installing $package using $pm"
    
    case "$pm" in
        "apt")
            sudo apt install -y $package
            ;;
        "pacman")
            sudo pacman -S --noconfirm $package
            ;;
        "yay")
            yay -S --noconfirm $package
            ;;
        "dnf")
            sudo dnf install -y $package
            ;;
        "zypper")
            sudo zypper install -y $package
            ;;
        "brew")
            brew install $package
            ;;
        "snap")
            sudo snap install $package
            ;;
        "flatpak")
            flatpak install -y $package
            ;;
        *)
            log_error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

remove_package() {
    local pm="$1"
    local package="$2"
    
    log_step "Removing $package using $pm"
    
    case "$pm" in
        "apt")
            sudo apt remove -y $package && sudo apt autoremove -y
            ;;
        "pacman")
            sudo pacman -Rs --noconfirm $package
            ;;
        "yay")
            yay -Rs --noconfirm $package
            ;;
        "dnf")
            sudo dnf remove -y $package
            ;;
        "zypper")
            sudo zypper remove -y $package
            ;;
        "brew")
            brew uninstall $package
            ;;
        "snap")
            sudo snap remove $package
            ;;
        "flatpak")
            flatpak uninstall -y $package
            ;;
        *)
            log_error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

check_package_installed() {
    local pm="$1"
    local package="$2"
    
    case "$pm" in
        "apt")
            dpkg -l | grep -qw "$package"
            ;;
        "pacman"|"yay")
            pacman -Qi "$package" >/dev/null 2>&1
            ;;
        "dnf")
            dnf list installed | grep -qw "$package"
            ;;
        "zypper")
            zypper se -i | grep -qw "$package"
            ;;
        "brew")
            brew list | grep -qw "$package"
            ;;
        "snap")
            snap list | grep -qw "$package"
            ;;
        "flatpak")
            flatpak list | grep -qw "$package"
            ;;
        *)
            log_error "Unknown package manager: $pm"
            return 1
            ;;
    esac
}

# =============================================================================
# JSON PROCESSING FUNCTIONS
# =============================================================================

get_json_value() {
    local json_file="$1"
    local key="$2"
    
    if command -v jq >/dev/null 2>&1; then
        jq -r "$key" "$json_file" 2>/dev/null || echo "null"
    else
        log_error "jq is required for JSON processing"
        return 1
    fi
}

set_json_value() {
    local json_file="$1"
    local key="$2"
    local value="$3"
    
    if command -v jq >/dev/null 2>&1; then
        local temp_file=$(mktemp)
        jq "$key = \"$value\"" "$json_file" > "$temp_file" && mv "$temp_file" "$json_file"
    else
        log_error "jq is required for JSON processing"
        return 1
    fi
}

get_program_config() {
    local program="$1"
    local config_key="$2"
    
    get_json_value "$SETTINGS_FILE" ".programs.${program}.${config_key}"
}

is_program_enabled() {
    local program="$1"
    local enabled=$(get_program_config "$program" "enabled")
    [[ "$enabled" == "true" ]]
}

get_install_method() {
    local program="$1"
    local pm="$2"
    
    get_json_value "$SETTINGS_FILE" ".programs.${program}.install_methods.${pm}"
}

# =============================================================================
# FILE SYSTEM FUNCTIONS
# =============================================================================

ensure_directory() {
    local dir="$1"
    
    if [[ ! -d "$dir" ]]; then
        log_step "Creating directory: $dir"
        mkdir -p "$dir"
    fi
}

backup_file() {
    local file="$1"
    local backup_dir="${PROJECT_ROOT}/backups/$(date +%Y%m%d_%H%M%S)"
    
    if [[ -f "$file" ]]; then
        ensure_directory "$backup_dir"
        cp "$file" "$backup_dir/"
        log_info "Backed up $file to $backup_dir/"
    fi
}

# =============================================================================
# VALIDATION FUNCTIONS
# =============================================================================

validate_settings() {
    if [[ ! -f "$SETTINGS_FILE" ]]; then
        log_error "Settings file not found: $SETTINGS_FILE"
        return 1
    fi
    
    if ! jq . "$SETTINGS_FILE" >/dev/null 2>&1; then
        log_error "Invalid JSON in settings file: $SETTINGS_FILE"
        return 1
    fi
    
    log_success "Settings file validated successfully"
    return 0
}

check_dependencies() {
    local deps=("jq" "curl" "wget")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" >/dev/null 2>&1; then
            missing_deps+=("$dep")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again"
        return 1
    fi
    
    return 0
}

# =============================================================================
# INITIALIZATION FUNCTION
# =============================================================================

init_utils() {
    # Set debug mode from settings
    local debug_mode=$(get_json_value "$SETTINGS_FILE" ".system.behavior.debug_mode")
    if [[ "$debug_mode" == "true" ]]; then
        export DEBUG_MODE=true
        set -x
    fi
    
    # Validate environment
    validate_settings || exit 1
    check_dependencies || exit 1
    
    log_info "Utils library initialized successfully"
}

# =============================================================================
# EXPORT FUNCTIONS
# =============================================================================

# This script is meant to be sourced, so we don't run anything automatically
# unless it's being executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Script is being run directly, show system info
    echo "System Information:"
    get_system_info | jq .
fi 