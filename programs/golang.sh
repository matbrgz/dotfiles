#!/bin/bash

# =============================================================================
# GO PROGRAMMING LANGUAGE INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install Go programming language with development environment
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_golang() {
	log_step "Installing Go programming language"
	
	local pm
	pm=$(detect_package_manager)
	
	# Get Go version from version.json
	local go_version
	go_version=$(get_json_value "$PROJECT_ROOT/bootstrap/version.json" ".golang")
	
	if [[ "$go_version" == "null" ]]; then
		log_warning "Go version not found in version.json, using 1.21"
		go_version="1.21"
	fi
	
	log_info "Installing Go v${go_version}"
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing Go installation"
		sudo rm -rf /usr/local/go 2>/dev/null || true
		rm -rf "$HOME/go" 2>/dev/null || true
		
		# Remove Go paths from shell profiles
		sed -i '/GOROOT/d' "$HOME/.bashrc" 2>/dev/null || true
		sed -i '/GOPATH/d' "$HOME/.bashrc" 2>/dev/null || true
		sed -i '/go\/bin/d' "$HOME/.bashrc" 2>/dev/null || true
	fi
	
	# Try package manager first
	case "$pm" in
		"apt")
			# Check if we can install Go from package manager
			if install_go_from_package; then
				return 0
			else
				install_go_from_binary "$go_version"
			fi
			;;
		"pacman")
			sudo pacman -S --noconfirm go 2>/dev/null || install_go_from_binary "$go_version"
			;;
		"yay")
			yay -S --noconfirm go 2>/dev/null || install_go_from_binary "$go_version"
			;;
		"dnf")
			sudo dnf install -y golang 2>/dev/null || install_go_from_binary "$go_version"
			;;
		"zypper")
			sudo zypper install -y go 2>/dev/null || install_go_from_binary "$go_version"
			;;
		"snap")
			sudo snap install go --classic
			;;
		"brew")
			brew install go
			;;
		*)
			install_go_from_binary "$go_version"
			;;
	esac
	
	log_success "Go installed successfully"
}

install_go_from_package() {
	log_step "Attempting to install Go from package manager"
	
	sudo apt update
	if sudo apt install -y golang-go; then
		log_success "Go installed from package manager"
		return 0
	else
		log_info "Package manager installation failed, falling back to binary"
		return 1
	fi
}

install_go_from_binary() {
	local go_version="$1"
	
	log_step "Installing Go from binary release"
	
	local architecture
	local os_type
	
	architecture=$(uname -m)
	os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
	
	# Map architecture names
	case "$architecture" in
		"x86_64")
			architecture="amd64"
			;;
		"i386"|"i686")
			architecture="386"
			;;
		"aarch64"|"arm64")
			architecture="arm64"
			;;
		"armv6l")
			architecture="armv6l"
			;;
		*)
			log_error "Unsupported architecture: $architecture"
			return 1
			;;
	esac
	
	local download_url="https://golang.org/dl/go${go_version}.${os_type}-${architecture}.tar.gz"
	local temp_file="/tmp/go${go_version}.${os_type}-${architecture}.tar.gz"
	
	log_info "Downloading Go ${go_version} for ${os_type}-${architecture}"
	
	# Download Go binary
	if curl -L "$download_url" -o "$temp_file"; then
		# Remove existing installation
		sudo rm -rf /usr/local/go
		
		# Extract to /usr/local
		sudo tar -C /usr/local -xzf "$temp_file"
		
		# Clean up
		rm -f "$temp_file"
		
		log_success "Go binary installed to /usr/local/go"
	else
		log_error "Failed to download Go binary"
		return 1
	fi
}

configure_golang() {
	log_step "Configuring Go environment"
	
	# Create Go workspace directories
	local gopath="$HOME/go"
	local gobin="$gopath/bin"
	
	mkdir -p "$gopath"/{src,pkg,bin}
	log_info "Created Go workspace at $gopath"
	
	# Configure environment variables
	local bashrc="$HOME/.bashrc"
	local go_config="# Go configuration added by matbrgz dotfiles"
	
	# Check if Go config already exists
	if ! grep -q "$go_config" "$bashrc" 2>/dev/null; then
		cat >> "$bashrc" << EOF

# Go configuration added by matbrgz dotfiles
export GOROOT=/usr/local/go
export GOPATH=$gopath
export GOBIN=$gobin
export PATH=\$PATH:\$GOROOT/bin:\$GOBIN

# Go aliases
alias go-version='go version'
alias go-env='go env'
alias go-install='go install'
alias go-build='go build'
alias go-run='go run'
alias go-test='go test'
alias go-fmt='go fmt'
alias go-vet='go vet'
alias go-mod-init='go mod init'
alias go-mod-tidy='go mod tidy'
alias go-mod-download='go mod download'
alias go-get='go get'
alias go-clean='go clean'
alias go-workspace='cd \$GOPATH'
EOF
		
		log_success "Go configuration added to $bashrc"
	else
		log_info "Go configuration already exists in $bashrc"
	fi
	
	# Export for current session
	export GOROOT=/usr/local/go
	export GOPATH="$gopath"
	export GOBIN="$gobin"
	export PATH="$PATH:$GOROOT/bin:$GOBIN"
}

install_go_tools() {
	log_step "Installing Go development tools"
	
	# Ensure Go is in PATH for current session
	export PATH="$PATH:/usr/local/go/bin:$HOME/go/bin"
	
	if ! command -v go >/dev/null 2>&1; then
		log_error "Go command not available"
		return 1
	fi
	
	local go_tools=(
		"golang.org/x/tools/cmd/goimports@latest"
		"golang.org/x/tools/cmd/godoc@latest"
		"golang.org/x/tools/cmd/gofmt@latest"
		"golang.org/x/lint/golint@latest"
		"honnef.co/go/tools/cmd/staticcheck@latest"
		"github.com/gorilla/mux@latest"
		"github.com/gin-gonic/gin@latest"
		"github.com/go-delve/delve/cmd/dlv@latest"
		"github.com/cosmtrek/air@latest"
		"github.com/swaggo/swag/cmd/swag@latest"
	)
	
	for tool in "${go_tools[@]}"; do
		log_info "Installing $tool"
		go install "$tool" 2>/dev/null || log_warning "Failed to install $tool"
	done
	
	log_success "Go development tools installed"
}

create_sample_project() {
	log_step "Creating sample Go project"
	
	local sample_dir="$HOME/go/src/hello"
	
	if [[ ! -d "$sample_dir" ]]; then
		mkdir -p "$sample_dir"
		
		cat > "$sample_dir/main.go" << 'EOF'
package main

import (
	"fmt"
	"net/http"
)

func main() {
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		fmt.Fprintf(w, "Hello, Go! 🚀\n")
		fmt.Fprintf(w, "Request URL: %s\n", r.URL.Path)
		fmt.Fprintf(w, "Method: %s\n", r.Method)
	})
	
	fmt.Println("Starting server on :8080")
	fmt.Println("Visit: http://localhost:8080")
	
	if err := http.ListenAndServe(":8080", nil); err != nil {
		fmt.Printf("Server error: %v\n", err)
	}
}
EOF
		
		cat > "$sample_dir/go.mod" << 'EOF'
module hello

go 1.21
EOF
		
		log_success "Sample project created at $sample_dir"
	else
		log_info "Sample project already exists"
	fi
}

verify_installation() {
	log_step "Verifying Go installation"
	
	# Add Go to PATH for verification
	export PATH="$PATH:/usr/local/go/bin"
	
	if command -v go >/dev/null 2>&1; then
		local go_version
		go_version=$(go version)
		log_success "Go version: $go_version"
		
		# Check Go environment
		local goroot gopath
		goroot=$(go env GOROOT 2>/dev/null || echo "not set")
		gopath=$(go env GOPATH 2>/dev/null || echo "not set")
		
		log_info "GOROOT: $goroot"
		log_info "GOPATH: $gopath"
		
		# Test compilation
		if echo 'package main; import "fmt"; func main() { fmt.Println("Hello, Go!") }' | go run -; then
			log_success "Go compilation test passed"
		else
			log_warning "Go compilation test failed"
		fi
		
	else
		log_error "Go command not found"
		log_info "Try restarting your shell or run: source ~/.bashrc"
		return 1
	fi
}

show_usage() {
	echo
	log_info "Go usage:"
	echo "  - Check version: go-version"
	echo "  - Initialize module: go-mod-init myproject"
	echo "  - Run program: go-run main.go"
	echo "  - Build binary: go-build"
	echo "  - Install package: go-get github.com/user/package"
	echo "  - Format code: go-fmt ./..."
	echo "  - Run tests: go-test ./..."
	echo "  - Go to workspace: go-workspace"
	echo
	log_info "Sample project:"
	echo "  - Location: $HOME/go/src/hello"
	echo "  - Run: cd $HOME/go/src/hello && go run main.go"
	echo "  - Visit: http://localhost:8080"
	echo
	log_info "Development tools installed:"
	echo "  - goimports, godoc, golint, staticcheck"
	echo "  - delve debugger (dlv), air (live reload)"
	echo "  - Popular frameworks: gin, mux"
}

main() {
	log_info "Starting Go programming language setup"
	
	install_golang
	configure_golang
	install_go_tools
	create_sample_project
	verify_installation
	show_usage
	
	log_success "Go setup completed successfully"
	log_info "Restart your shell or run 'source ~/.bashrc' to use Go"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
