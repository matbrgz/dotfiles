#!/bin/bash

# =============================================================================
# KUBECTL INSTALLATION SCRIPT
# =============================================================================
# Author: matbrgz
# Description: Install kubectl for Kubernetes cluster management
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Source utilities
source "$PROJECT_ROOT/lib/utils.sh"

install_kubectl() {
	log_step "Installing kubectl"
	
	local pm
	pm=$(detect_package_manager)
	
	# Get kubectl version from version.json
	local kubectl_version
	kubectl_version=$(get_json_value "$PROJECT_ROOT/bootstrap/version.json" ".kubectl")
	
	if [[ "$kubectl_version" == "null" ]]; then
		log_warning "kubectl version not found in version.json, using latest"
		kubectl_version="latest"
	fi
	
	log_info "Installing kubectl v${kubectl_version}"
	
	# Check if purge mode is enabled
	if [[ "$(get_json_value "$PROJECT_ROOT/bootstrap/settings.json" ".system.behavior.purge_mode")" == "true" ]]; then
		log_step "Purging existing kubectl installation"
		sudo rm -f /usr/local/bin/kubectl /usr/bin/kubectl 2>/dev/null || true
		
		case "$pm" in
			"apt")
				sudo apt remove -y kubectl 2>/dev/null || true
				sudo apt autoremove -y
				;;
			"pacman"|"yay")
				sudo pacman -Rs --noconfirm kubectl 2>/dev/null || true
				;;
			"dnf")
				sudo dnf remove -y kubectl 2>/dev/null || true
				;;
		esac
	fi
	
	# Try package manager first, then fallback to binary installation
	case "$pm" in
		"apt")
			if install_kubectl_apt; then
				return 0
			else
				install_kubectl_binary "$kubectl_version"
			fi
			;;
		"pacman")
			sudo pacman -S --noconfirm kubectl 2>/dev/null || install_kubectl_binary "$kubectl_version"
			;;
		"yay")
			yay -S --noconfirm kubectl 2>/dev/null || install_kubectl_binary "$kubectl_version"
			;;
		"dnf")
			sudo dnf install -y kubectl 2>/dev/null || install_kubectl_binary "$kubectl_version"
			;;
		"zypper")
			sudo zypper install -y kubectl 2>/dev/null || install_kubectl_binary "$kubectl_version"
			;;
		"snap")
			sudo snap install kubectl --classic
			;;
		"brew")
			brew install kubectl
			;;
		*)
			install_kubectl_binary "$kubectl_version"
			;;
	esac
	
	log_success "kubectl installed successfully"
}

install_kubectl_apt() {
	log_step "Installing kubectl via APT"
	
	# Add Kubernetes repository
	sudo apt update
	sudo apt install -y apt-transport-https ca-certificates curl gnupg
	
	# Add Kubernetes signing key
	if curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.31/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg; then
		# Add repository
		echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.31/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
		
		sudo apt update
		sudo apt install -y kubectl
		
		log_success "kubectl installed via APT"
		return 0
	else
		log_warning "Failed to add Kubernetes repository, falling back to binary installation"
		return 1
	fi
}

install_kubectl_binary() {
	local kubectl_version="$1"
	
	log_step "Installing kubectl from binary release"
	
	local architecture
	local os_type
	
	architecture=$(uname -m)
	os_type=$(uname -s | tr '[:upper:]' '[:lower:]')
	
	# Map architecture names
	case "$architecture" in
		"x86_64")
			architecture="amd64"
			;;
		"aarch64"|"arm64")
			architecture="arm64"
			;;
		"armv7l")
			architecture="arm"
			;;
		*)
			log_error "Unsupported architecture: $architecture"
			return 1
			;;
	esac
	
	# Get download URL
	local download_url
	if [[ "$kubectl_version" == "latest" ]]; then
		# Get latest stable version
		kubectl_version=$(curl -L -s https://dl.k8s.io/release/stable.txt)
		download_url="https://dl.k8s.io/release/${kubectl_version}/bin/${os_type}/${architecture}/kubectl"
	else
		download_url="https://dl.k8s.io/release/v${kubectl_version}/bin/${os_type}/${architecture}/kubectl"
	fi
	
	log_info "Downloading kubectl ${kubectl_version} for ${os_type}-${architecture}"
	
	# Download and install
	if curl -L "$download_url" -o /tmp/kubectl; then
		sudo mv /tmp/kubectl /usr/local/bin/kubectl
		sudo chmod +x /usr/local/bin/kubectl
		
		# Create symlink for convenience
		sudo ln -sf /usr/local/bin/kubectl /usr/bin/kubectl 2>/dev/null || true
		
		log_success "kubectl binary installed to /usr/local/bin/kubectl"
	else
		log_error "Failed to download kubectl binary"
		return 1
	fi
}

configure_kubectl() {
	log_step "Configuring kubectl"
	
	# Create kubectl config directory
	local kube_dir="$HOME/.kube"
	mkdir -p "$kube_dir"
	chmod 700 "$kube_dir"
	
	# Create basic config file if it doesn't exist
	local kube_config="$kube_dir/config"
	if [[ ! -f "$kube_config" ]]; then
		cat > "$kube_config" << 'EOF'
apiVersion: v1
kind: Config
clusters: []
contexts: []
current-context: ""
preferences: {}
users: []
EOF
		
		chmod 600 "$kube_config"
		log_success "kubectl config file created at $kube_config"
	else
		log_info "kubectl config file already exists"
	fi
}

setup_bash_completion() {
	log_step "Setting up bash completion for kubectl"
	
	local completion_dir="/etc/bash_completion.d"
	local completion_file="$completion_dir/kubectl"
	
	if [[ -d "$completion_dir" ]]; then
		# Generate kubectl completion
		if command -v kubectl >/dev/null 2>&1; then
			kubectl completion bash | sudo tee "$completion_file" > /dev/null
			log_success "kubectl bash completion configured"
		else
			log_warning "kubectl not available for completion generation"
		fi
	else
		log_warning "Bash completion directory not found, skipping"
	fi
	
	# Add completion to user's bashrc
	local bashrc="$HOME/.bashrc"
	local completion_section="# kubectl completion added by matbrgz dotfiles"
	
	if ! grep -q "$completion_section" "$bashrc" 2>/dev/null; then
		cat >> "$bashrc" << 'EOF'

# kubectl completion added by matbrgz dotfiles
if command -v kubectl >/dev/null 2>&1; then
    source <(kubectl completion bash)
    complete -F __start_kubectl k
fi
EOF
		
		log_success "kubectl completion added to $bashrc"
	fi
}

create_kubectl_aliases() {
	log_step "Creating kubectl aliases"
	
	local bashrc="$HOME/.bashrc"
	local aliases_section="# kubectl aliases added by matbrgz dotfiles"
	
	# Check if aliases already exist
	if grep -q "$aliases_section" "$bashrc" 2>/dev/null; then
		log_info "kubectl aliases already exist in $bashrc"
		return 0
	fi
	
	# Add kubectl aliases
	cat >> "$bashrc" << 'EOF'

# kubectl aliases added by matbrgz dotfiles
alias k='kubectl'
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kgn='kubectl get nodes'
alias kga='kubectl get all'
alias kdp='kubectl describe pod'
alias kds='kubectl describe service'
alias kdd='kubectl describe deployment'
alias kdn='kubectl describe node'
alias kaf='kubectl apply -f'
alias kdf='kubectl delete -f'
alias kex='kubectl exec -it'
alias klogs='kubectl logs'
alias klogsf='kubectl logs -f'
alias kctx='kubectl config current-context'
alias kctxs='kubectl config get-contexts'
alias kctxu='kubectl config use-context'
alias kns='kubectl config set-context --current --namespace'

# kubectl helpers
alias k-pods='kubectl get pods --all-namespaces'
alias k-nodes='kubectl get nodes -o wide'
alias k-top-pods='kubectl top pods'
alias k-top-nodes='kubectl top nodes'
alias k-watch-pods='kubectl get pods -w'
alias k-port-forward='kubectl port-forward'
EOF
	
	log_success "kubectl aliases added to $bashrc"
}

install_additional_tools() {
	log_step "Installing additional Kubernetes tools"
	
	# Install kubectx and kubens for easier context/namespace switching
	local tools_dir="/usr/local/bin"
	
	# kubectx
	if ! command -v kubectx >/dev/null 2>&1; then
		log_info "Installing kubectx"
		if curl -L https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx -o /tmp/kubectx; then
			sudo mv /tmp/kubectx "$tools_dir/kubectx"
			sudo chmod +x "$tools_dir/kubectx"
			log_success "kubectx installed"
		else
			log_warning "Failed to install kubectx"
		fi
	fi
	
	# kubens
	if ! command -v kubens >/dev/null 2>&1; then
		log_info "Installing kubens"
		if curl -L https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens -o /tmp/kubens; then
			sudo mv /tmp/kubens "$tools_dir/kubens"
			sudo chmod +x "$tools_dir/kubens"
			log_success "kubens installed"
		else
			log_warning "Failed to install kubens"
		fi
	fi
}

verify_installation() {
	log_step "Verifying kubectl installation"
	
	if command -v kubectl >/dev/null 2>&1; then
		local version
		version=$(kubectl version --client --short 2>/dev/null || kubectl version --client 2>/dev/null | head -1)
		log_success "kubectl version: $version"
		
		# Check if kubectl can connect to a cluster
		if kubectl cluster-info >/dev/null 2>&1; then
			log_success "kubectl can connect to a Kubernetes cluster"
		else
			log_info "kubectl installed but no cluster configured"
			log_info "Use 'kubectl config' commands to configure cluster access"
		fi
		
		# Check additional tools
		if command -v kubectx >/dev/null 2>&1; then
			log_success "kubectx is available"
		fi
		
		if command -v kubens >/dev/null 2>&1; then
			log_success "kubens is available"
		fi
		
	else
		log_error "kubectl command not found"
		return 1
	fi
}

show_usage() {
	echo
	log_info "kubectl usage:"
	echo "  - Get pods: kgp or kubectl get pods"
	echo "  - Get all resources: kga"
	echo "  - Apply config: kaf file.yaml"
	echo "  - Execute in pod: kex pod-name -- /bin/bash"
	echo "  - View logs: klogs pod-name"
	echo "  - Port forward: k-port-forward pod-name 8080:80"
	echo
	log_info "Context management:"
	echo "  - Current context: kctx"
	echo "  - List contexts: kctxs"
	echo "  - Switch context: kctxu context-name"
	echo "  - Switch namespace: kns namespace-name"
	echo
	log_info "Additional tools:"
	echo "  - kubectx: Switch between clusters"
	echo "  - kubens: Switch between namespaces"
	echo
	log_info "Configuration:"
	echo "  - Config file: $HOME/.kube/config"
	echo "  - Add cluster: kubectl config set-cluster"
	echo "  - Add user: kubectl config set-credentials"
	echo "  - Add context: kubectl config set-context"
}

main() {
	log_info "Starting kubectl setup"
	
	install_kubectl
	configure_kubectl
	setup_bash_completion
	create_kubectl_aliases
	install_additional_tools
	verify_installation
	show_usage
	
	log_success "kubectl setup completed successfully"
	log_info "Use 'source ~/.bashrc' to load new aliases and completion"
}

# Run main function if script is executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
	main "$@"
fi
