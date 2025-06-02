#!/bin/bash

# =============================================================================
# GIT CONFIGURATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Configure Git with personalized settings
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

main() {
    log_info "Starting Git configuration"
    
    # Get personal settings
    local name email
    name=$(get_json_value "$PROJECT_ROOT/settings.json" ".personal.name")
    email=$(get_json_value "$PROJECT_ROOT/settings.json" ".personal.email")
    
    if [[ "$name" == "null" || "$email" == "null" ]]; then
        log_warning "Personal name or email not set in settings.json"
        log_info "Please update your personal information in settings.json"
        return 1
    fi
    
    # Run Git configuration from the main Git script
    bash "$PROJECT_ROOT/programs/git.sh"
    
    log_success "Git configuration completed"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi 