#!/bin/bash

# =============================================================================
# DOTFILES INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Universal dotfiles installation script for Linux distributions
# Supports: Ubuntu, Debian, Arch Linux, Fedora, openSUSE, and more
# =============================================================================

set -euo pipefail

# Script constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$SCRIPT_DIR"
readonly SETTINGS_FILE="$PROJECT_ROOT/settings.json"
readonly UTILS_LIB="$PROJECT_ROOT/lib/utils.sh"

# Global variables
TOTAL_START_TIME=$(date +%s)
PACKAGE_MANAGER=""
OS_TYPE=""
DISTRO=""

# =============================================================================
# LOAD UTILITIES
# =============================================================================

if [[ ! -f "$UTILS_LIB" ]]; then
    echo "ERROR: Utils library not found at $UTILS_LIB"
    exit 1
fi

source "$UTILS_LIB"

# =============================================================================
# MAIN FUNCTIONS
# =============================================================================

show_banner() {
    cat << 'EOF'
 ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗
 ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝
 ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗
 ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║
 ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║
 ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝
                                                    by matbrgz
EOF
    echo
    log_info "Universal System Setup & Configuration Tool"
    echo
}

check_prerequisites() {
    log_step "Checking prerequisites"
    
    # Check if running as root
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root"
        log_info "Please run as a regular user with sudo privileges"
        exit 1
    fi
    
    # Check sudo access
    if ! sudo -n true 2>/dev/null; then
        log_info "This script requires sudo privileges"
        sudo -v || {
            log_error "Failed to obtain sudo privileges"
            exit 1
        }
    fi
    
    # Install essential dependencies
    install_dependencies
    
    log_success "Prerequisites check completed"
}

install_dependencies() {
    log_step "Installing essential dependencies"
    
    # Detect system first
    OS_TYPE=$(detect_os)
    DISTRO=$(detect_distro)
    PACKAGE_MANAGER=$(detect_package_manager)
    
    log_info "Detected: $OS_TYPE ($DISTRO) with $PACKAGE_MANAGER"
    
    # Install jq if not present
    if ! command -v jq >/dev/null 2>&1; then
        log_step "Installing jq for JSON processing"
        case "$PACKAGE_MANAGER" in
            "apt")
                sudo apt update && sudo apt install -y jq
                ;;
            "pacman")
                sudo pacman -S --noconfirm jq
                ;;
            "yay")
                yay -S --noconfirm jq
                ;;
            "dnf")
                sudo dnf install -y jq
                ;;
            *)
                log_error "Please install jq manually for your system"
                exit 1
                ;;
        esac
    fi
    
    # Update package manager
    update_package_manager "$PACKAGE_MANAGER"
}

setup_environment() {
    log_step "Setting up environment"
    
    # Initialize utils library
    init_utils
    
    # Create necessary directories
    ensure_directory "$PROJECT_ROOT/logs"
    ensure_directory "$PROJECT_ROOT/backups"
    ensure_directory "$PROJECT_ROOT/tmp"
    
    # Set log file
    LOG_FILE="$PROJECT_ROOT/logs/install_$(date +%Y%m%d_%H%M%S).log"
    exec > >(tee -a "$LOG_FILE")
    exec 2>&1
    
    log_success "Environment setup completed"
}

show_system_info() {
    log_step "System Information"
    
    local system_info
    system_info=$(get_system_info)
    
    echo "$system_info" | jq .
    echo
}

configure_personal_settings() {
    log_step "Configuring personal settings"
    
    local current_name current_email current_github
    
    current_name=$(get_json_value "$SETTINGS_FILE" ".personal.name")
    current_email=$(get_json_value "$SETTINGS_FILE" ".personal.email")
    current_github=$(get_json_value "$SETTINGS_FILE" ".personal.githubuser")
    
    echo
    log_info "Current personal settings:"
    echo "  Name: $current_name"
    echo "  Email: $current_email"
    echo "  GitHub: $current_github"
    echo
    
    read -p "Do you want to update personal settings? (y/N): " -r update_personal
    if [[ $update_personal =~ ^[Yy]$ ]]; then
        read -p "Enter your full name [$current_name]: " -r new_name
        read -p "Enter your email [$current_email]: " -r new_email
        read -p "Enter your GitHub username [$current_github]: " -r new_github
        
        # Update settings if provided
        [[ -n "$new_name" ]] && set_json_value "$SETTINGS_FILE" ".personal.name" "$new_name"
        [[ -n "$new_email" ]] && set_json_value "$SETTINGS_FILE" ".personal.email" "$new_email"
        [[ -n "$new_github" ]] && set_json_value "$SETTINGS_FILE" ".personal.githubuser" "$new_github"
        
        log_success "Personal settings updated"
    fi
}

show_installation_menu() {
    log_step "Installation Options"
    
    echo
    echo "Please choose an installation type:"
    echo
    echo "  1) Express Install    - Install essential tools with default settings"
    echo "  2) Custom Install     - Choose programs to install interactively"
    echo "  3) Preset Install     - Use predefined installation presets"
    echo "  4) Config Only        - Only configure already installed programs"
    echo "  5) System Info        - Show system information and exit"
    echo "  0) Exit               - Exit without installing"
    echo
    
    read -p "Enter your choice [1-5,0]: " -r choice
    
    case "$choice" in
        1) install_type="express" ;;
        2) install_type="custom" ;;
        3) install_type="preset" ;;
        4) install_type="config" ;;
        5) show_system_info; exit 0 ;;
        0) log_info "Installation cancelled by user"; exit 0 ;;
        *) log_error "Invalid choice"; show_installation_menu ;;
    esac
    
    echo "$install_type"
}

handle_express_install() {
    log_step "Express Installation"
    
    log_info "Installing essential tools with default settings"
    
    # Enable all default programs
    local programs
    programs=$(get_json_value "$SETTINGS_FILE" '.programs | to_entries[] | select(.value.default == true) | .key')
    
    while IFS= read -r program; do
        if [[ -n "$program" && "$program" != "null" ]]; then
            set_json_value "$SETTINGS_FILE" ".programs.${program}.enabled" "true"
        fi
    done <<< "$programs"
    
    install_programs
}

handle_custom_install() {
    log_step "Custom Installation"
    
    # Show categories
    echo
    log_info "Available program categories:"
    echo
    
    local categories
    categories=$(get_json_value "$SETTINGS_FILE" '.categories | to_entries[] | "\(.key): \(.value.name) - \(.value.description)"')
    
    local i=1
    declare -A category_map
    
    while IFS= read -r category_info; do
        if [[ -n "$category_info" && "$category_info" != "null" ]]; then
            echo "  $i) $category_info"
            local category_key=$(echo "$category_info" | cut -d':' -f1)
            category_map[$i]="$category_key"
            ((i++))
        fi
    done <<< "$categories"
    
    echo
    read -p "Select categories to install (comma-separated numbers): " -r selected_categories
    
    # Enable programs from selected categories
    IFS=',' read -ra CATEGORY_NUMS <<< "$selected_categories"
    for num in "${CATEGORY_NUMS[@]}"; do
        num=$(echo "$num" | tr -d ' ')
        if [[ -n "${category_map[$num]:-}" ]]; then
            local category="${category_map[$num]}"
            local programs_in_category
            programs_in_category=$(get_json_value "$SETTINGS_FILE" ".categories.${category}.programs[]")
            
            while IFS= read -r program; do
                if [[ -n "$program" && "$program" != "null" ]]; then
                    program=$(echo "$program" | tr -d '"')
                    set_json_value "$SETTINGS_FILE" ".programs.${program}.enabled" "true"
                fi
            done <<< "$programs_in_category"
        fi
    done
    
    install_programs
}

handle_preset_install() {
    log_step "Preset Installation"
    
    echo
    log_info "Available presets:"
    echo
    
    local presets
    presets=$(get_json_value "$SETTINGS_FILE" '.presets | to_entries[] | "\(.key): \(.value.name) - \(.value.description)"')
    
    local i=1
    declare -A preset_map
    
    while IFS= read -r preset_info; do
        if [[ -n "$preset_info" && "$preset_info" != "null" ]]; then
            echo "  $i) $preset_info"
            local preset_key=$(echo "$preset_info" | cut -d':' -f1)
            preset_map[$i]="$preset_key"
            ((i++))
        fi
    done <<< "$presets"
    
    echo
    read -p "Select a preset [1-$((i-1))]: " -r preset_choice
    
    if [[ -n "${preset_map[$preset_choice]:-}" ]]; then
        local preset="${preset_map[$preset_choice]}"
        local programs_in_preset
        programs_in_preset=$(get_json_value "$SETTINGS_FILE" ".presets.${preset}.programs[]")
        
        while IFS= read -r program; do
            if [[ -n "$program" && "$program" != "null" ]]; then
                program=$(echo "$program" | tr -d '"')
                set_json_value "$SETTINGS_FILE" ".programs.${program}.enabled" "true"
            fi
        done <<< "$programs_in_preset"
        
        install_programs
    else
        log_error "Invalid preset selection"
        exit 1
    fi
}

install_programs() {
    log_step "Installing Programs"
    
    local enabled_programs
    enabled_programs=$(get_json_value "$SETTINGS_FILE" '.programs | to_entries[] | select(.value.enabled == true) | .key')
    
    local program_count=0
    while IFS= read -r program; do
        if [[ -n "$program" && "$program" != "null" ]]; then
            ((program_count++))
        fi
    done <<< "$enabled_programs"
    
    if [[ $program_count -eq 0 ]]; then
        log_warning "No programs enabled for installation"
        return
    fi
    
    log_info "Installing $program_count programs"
    echo
    
    local current=0
    while IFS= read -r program; do
        if [[ -n "$program" && "$program" != "null" ]]; then
            ((current++))
            install_program "$program" "$current" "$program_count"
        fi
    done <<< "$enabled_programs"
    
    log_success "All programs installed successfully"
}

install_program() {
    local program="$1"
    local current="$2"
    local total="$3"
    
    local program_name
    program_name=$(get_program_config "$program" "name")
    
    log_step "[$current/$total] Installing $program_name"
    
    local install_method
    install_method=$(get_install_method "$program" "$PACKAGE_MANAGER")
    
    if [[ "$install_method" == "null" || -z "$install_method" ]]; then
        log_warning "No install method found for $program using $PACKAGE_MANAGER"
        return
    fi
    
    # Check if already installed
    local first_package
    first_package=$(echo "$install_method" | awk '{print $1}')
    
    if check_package_installed "$PACKAGE_MANAGER" "$first_package"; then
        log_info "$program_name is already installed, skipping"
    else
        # Install the program
        install_package "$PACKAGE_MANAGER" "$install_method"
        
        # Run post-install configuration if available
        run_post_install "$program"
    fi
}

run_post_install() {
    local program="$1"
    
    local config_file
    config_file=$(get_program_config "$program" "config_file")
    
    if [[ "$config_file" != "null" && -n "$config_file" ]]; then
        local config_script="$PROJECT_ROOT/programs/configs/$config_file"
        if [[ -f "$config_script" ]]; then
            log_step "Configuring $program"
            bash "$config_script" "$PROJECT_ROOT"
        fi
    fi
    
    local post_install_actions
    post_install_actions=$(get_json_value "$SETTINGS_FILE" ".programs.${program}.post_install[]")
    
    while IFS= read -r action; do
        if [[ -n "$action" && "$action" != "null" ]]; then
            action=$(echo "$action" | tr -d '"')
            run_post_install_action "$action" "$program"
        fi
    done <<< "$post_install_actions"
}

run_post_install_action() {
    local action="$1"
    local program="$2"
    
    case "$action" in
        "git_config")
            configure_git
            ;;
        "docker_user_group")
            configure_docker_user
            ;;
        "python_config")
            configure_python
            ;;
        *)
            log_debug "Unknown post-install action: $action for $program"
            ;;
    esac
}

configure_git() {
    local name email
    name=$(get_json_value "$SETTINGS_FILE" ".personal.name")
    email=$(get_json_value "$SETTINGS_FILE" ".personal.email")
    
    if [[ "$name" != "null" && "$email" != "null" ]]; then
        git config --global user.name "$name"
        git config --global user.email "$email"
        log_success "Git configured with name: $name, email: $email"
    fi
}

configure_docker_user() {
    if ! groups "$USER" | grep -q docker; then
        sudo usermod -aG docker "$USER"
        log_info "Added $USER to docker group (logout/login required)"
    fi
}

configure_python() {
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --upgrade pip
        log_success "Python pip upgraded"
    fi
}

cleanup() {
    log_step "Cleaning up"
    
    # Remove temporary files
    rm -rf "$PROJECT_ROOT/tmp"
    
    # Clean package manager cache
    case "$PACKAGE_MANAGER" in
        "apt")
            sudo apt autoremove -y && sudo apt autoclean
            ;;
        "pacman"|"yay")
            sudo pacman -Sc --noconfirm
            ;;
        *)
            log_debug "No cleanup method for $PACKAGE_MANAGER"
            ;;
    esac
    
    log_success "Cleanup completed"
}

show_summary() {
    local total_time=$(($(date +%s) - TOTAL_START_TIME))
    
    echo
    log_success "Installation completed successfully!"
    echo
    log_info "Summary:"
    echo "  - Total time: ${total_time}s"
    echo "  - Log file: $LOG_FILE"
    echo "  - System: $OS_TYPE ($DISTRO)"
    echo "  - Package manager: $PACKAGE_MANAGER"
    echo
    log_info "Thank you for using matbrgz dotfiles!"
    echo
}

# =============================================================================
# MAIN EXECUTION
# =============================================================================

main() {
    show_banner
    check_prerequisites
    setup_environment
    show_system_info
    configure_personal_settings
    
    local install_type
    install_type=$(show_installation_menu)
    
    case "$install_type" in
        "express")
            handle_express_install
            ;;
        "custom")
            handle_custom_install
            ;;
        "preset")
            handle_preset_install
            ;;
        "config")
            log_info "Configuration-only mode not implemented yet"
            ;;
        *)
            log_error "Unknown installation type: $install_type"
            exit 1
            ;;
    esac
    
    cleanup
    show_summary
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 