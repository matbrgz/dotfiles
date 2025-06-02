#!/bin/bash

# Google Cloud SDK Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="Google Cloud SDK"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_gcloudsdk_version() {
	gcloudsdk_version=$(get_json_value "gcloudsdk")
	if [[ -z "$gcloudsdk_version" || "$gcloudsdk_version" == "null" ]]; then
		gcloudsdk_version="507.0.0"
	fi
	echo "$gcloudsdk_version"
}

# Check if Google Cloud SDK is already installed
check_gcloudsdk_installation() {
	if command -v gcloud >/dev/null 2>&1; then
		log_warning "Google Cloud SDK is already installed"
		gcloud --version | head -n1
		return 0
	fi
	return 1
}

# Install Google Cloud SDK
install_gcloudsdk() {
	log_step "Installing Google Cloud SDK"
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Install prerequisites
			sudo apt-get update
			sudo apt-get install -y apt-transport-https ca-certificates gnupg curl
			
			# Add Google Cloud public key
			curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
				sudo gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
			
			# Add Google Cloud SDK repository
			echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | \
				sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
			
			# Update package list and install
			sudo apt-get update
			sudo apt-get install -y google-cloud-cli google-cloud-cli-kubectl \
				google-cloud-cli-gke-gcloud-auth-plugin google-cloud-cli-docker-credential-gcr
			;;
		yay|pacman)
			# Install from AUR or official repositories
			if command -v yay >/dev/null 2>&1; then
				yay -S --noconfirm google-cloud-sdk
			else
				# Manual installation for Arch
				install_gcloudsdk_manual
			fi
			;;
		dnf)
			# Add Google Cloud repository
			sudo tee -a /etc/yum.repos.d/google-cloud-sdk.repo << 'EOF'
[google-cloud-cli]
name=Google Cloud CLI
baseurl=https://packages.cloud.google.com/yum/repos/cloud-sdk-el8-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=0
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
       https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF
			
			# Install Google Cloud SDK
			sudo dnf install -y google-cloud-cli google-cloud-cli-kubectl
			;;
		zypper)
			# Add Google Cloud repository
			sudo zypper addrepo https://packages.cloud.google.com/yum/repos/cloud-sdk-opensuse15-x86_64 google-cloud-sdk
			sudo zypper --gpg-auto-import-keys refresh
			sudo zypper install -y google-cloud-cli google-cloud-cli-kubectl
			;;
		brew)
			# Install Google Cloud SDK via Homebrew
			brew install --cask google-cloud-sdk
			;;
		*)
			log_warning "Package manager not supported, attempting manual installation"
			install_gcloudsdk_manual
			;;
	esac
	
	log_success "Google Cloud SDK installed successfully"
}

# Install Google Cloud SDK manually (fallback method)
install_gcloudsdk_manual() {
	log_step "Installing Google Cloud SDK manually"
	
	local gcloud_version arch os_name
	gcloud_version=$(get_gcloudsdk_version)
	
	# Detect architecture and OS
	case "$(uname -m)" in
		x86_64) arch="x86_64" ;;
		aarch64|arm64) arch="arm" ;;
		*) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
	esac
	
	case "$(uname -s)" in
		Linux) os_name="linux" ;;
		Darwin) os_name="darwin" ;;
		*) log_error "Unsupported OS: $(uname -s)"; return 1 ;;
	esac
	
	# Download and install Google Cloud SDK
	local download_url="https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${gcloud_version}-${os_name}-${arch}.tar.gz"
	local install_dir="$HOME/google-cloud-sdk"
	local temp_file="/tmp/google-cloud-sdk.tar.gz"
	
	log_step "Downloading Google Cloud SDK $gcloud_version"
	curl -fsSL "$download_url" -o "$temp_file"
	
	# Remove existing installation if present
	if [[ -d "$install_dir" ]]; then
		rm -rf "$install_dir"
	fi
	
	log_step "Extracting Google Cloud SDK"
	tar -xzf "$temp_file" -C "$HOME"
	
	# Run installation script
	"$install_dir/install.sh" --quiet --usage-reporting=false --command-completion=true --path-update=true
	
	# Add to PATH
	if ! grep -q "google-cloud-sdk" "$CONFIG_FILE" 2>/dev/null; then
		echo "source '$install_dir/path.bash.inc'" >> "$CONFIG_FILE"
		echo "source '$install_dir/completion.bash.inc'" >> "$CONFIG_FILE"
	fi
	
	# Source for current session
	source "$install_dir/path.bash.inc"
	source "$install_dir/completion.bash.inc"
	
	# Cleanup
	rm -f "$temp_file"
	
	log_success "Google Cloud SDK manual installation completed"
}

# Configure Google Cloud SDK
configure_gcloudsdk() {
	log_step "Configuring Google Cloud SDK"
	
	# Initialize gcloud configuration (without browser)
	gcloud config set core/disable_usage_reporting true
	gcloud config set component_manager/disable_update_check true
	gcloud config set core/disable_prompts true
	
	# Set default configuration values
	gcloud config set compute/region us-central1
	gcloud config set compute/zone us-central1-a
	
	log_success "Google Cloud SDK configured with default settings"
}

# Install useful Google Cloud SDK components
install_gcloud_components() {
	log_step "Installing useful Google Cloud SDK components"
	
	# Essential components
	local components=(
		"kubectl"              # Kubernetes command-line tool
		"docker-credential-gcr" # Docker credential helper
		"beta"                 # Beta commands
		"alpha"                # Alpha commands
		"app-engine-python"    # App Engine Python runtime
		"app-engine-go"        # App Engine Go runtime
		"cloud-sql-proxy"      # Cloud SQL Proxy
		"pubsub-emulator"      # Pub/Sub emulator
		"datastore-emulator"   # Datastore emulator
		"firestore-emulator"   # Firestore emulator
	)
	
	for component in "${components[@]}"; do
		if ! gcloud components list --filter="id:$component" --format="value(state.name)" | grep -q "Installed"; then
			log_step "Installing component: $component"
			gcloud components install "$component" --quiet || log_warning "Failed to install $component"
		fi
	done
	
	log_success "Google Cloud SDK components installed"
}

# Create sample Google Cloud configurations
create_sample_configs() {
	log_step "Creating sample Google Cloud configurations"
	
	local gcloud_samples="$HOME/gcloud-samples"
	mkdir -p "$gcloud_samples"
	
	# Create deployment manager template
	local deployment_template="$gcloud_samples/vm-deployment.yaml"
	if [[ ! -f "$deployment_template" ]]; then
		cat > "$deployment_template" << 'EOF'
# Google Cloud Deployment Manager Template
# Creates a simple VM instance

resources:
- name: sample-vm
  type: compute.v1.instance
  properties:
    zone: us-central1-a
    machineType: zones/us-central1-a/machineTypes/e2-micro
    disks:
    - deviceName: boot
      type: PERSISTENT
      boot: true
      autoDelete: true
      initializeParams:
        sourceImage: projects/debian-cloud/global/images/family/debian-12
    networkInterfaces:
    - network: global/networks/default
      accessConfigs:
      - name: External NAT
        type: ONE_TO_ONE_NAT
    metadata:
      items:
      - key: startup-script
        value: |
          #!/bin/bash
          apt-get update
          apt-get install -y nginx
          systemctl start nginx
          systemctl enable nginx
          echo "Hello from GCP!" > /var/www/html/index.html

- name: sample-firewall
  type: compute.v1.firewall
  properties:
    allowed:
    - IPProtocol: TCP
      ports: ["80", "443"]
    sourceRanges: ["0.0.0.0/0"]
    targetTags: ["http-server"]
EOF
		log_success "Deployment Manager template created at $deployment_template"
	fi
	
	# Create gcloud examples script
	local gcloud_examples="$gcloud_samples/gcloud-examples.sh"
	if [[ ! -f "$gcloud_examples" ]]; then
		cat > "$gcloud_examples" << 'EOF'
#!/bin/bash

# Google Cloud CLI Examples Script
# Common gcloud commands for daily operations

set -euo pipefail

echo "Google Cloud CLI Examples"
echo "========================"

# Authentication
echo "1. Authentication:"
echo "   gcloud auth login                     # Interactive login"
echo "   gcloud auth application-default login # Set application default credentials"
echo "   gcloud auth list                      # List authenticated accounts"
echo ""

# Project management
echo "2. Project management:"
echo "   gcloud projects list                  # List all projects"
echo "   gcloud config set project PROJECT_ID # Set default project"
echo "   gcloud config get-value project      # Get current project"
echo ""

# Compute Engine
echo "3. Compute Engine operations:"
echo "   gcloud compute instances list         # List VM instances"
echo "   gcloud compute instances create my-vm --zone=us-central1-a --machine-type=e2-micro"
echo "   gcloud compute instances start my-vm --zone=us-central1-a"
echo "   gcloud compute instances stop my-vm --zone=us-central1-a"
echo "   gcloud compute instances delete my-vm --zone=us-central1-a"
echo ""

# Google Kubernetes Engine
echo "4. GKE operations:"
echo "   gcloud container clusters list        # List GKE clusters"
echo "   gcloud container clusters create my-cluster --zone=us-central1-a"
echo "   gcloud container clusters get-credentials my-cluster --zone=us-central1-a"
echo "   gcloud container clusters delete my-cluster --zone=us-central1-a"
echo ""

# Cloud Storage
echo "5. Cloud Storage operations:"
echo "   gsutil ls                             # List buckets"
echo "   gsutil mb gs://my-bucket              # Create bucket"
echo "   gsutil cp file.txt gs://my-bucket/    # Upload file"
echo "   gsutil cp gs://my-bucket/file.txt .   # Download file"
echo "   gsutil rm gs://my-bucket/file.txt     # Delete file"
echo ""

# Cloud Functions
echo "6. Cloud Functions operations:"
echo "   gcloud functions list                 # List functions"
echo "   gcloud functions deploy hello-world --runtime=python39 --trigger=http"
echo "   gcloud functions call hello-world"
echo "   gcloud functions delete hello-world"
echo ""

# App Engine
echo "7. App Engine operations:"
echo "   gcloud app deploy                     # Deploy application"
echo "   gcloud app browse                     # Open app in browser"
echo "   gcloud app logs tail -s default       # Stream logs"
echo "   gcloud app versions list              # List versions"
echo ""

# Cloud SQL
echo "8. Cloud SQL operations:"
echo "   gcloud sql instances list             # List SQL instances"
echo "   gcloud sql instances create my-instance --tier=db-f1-micro"
echo "   gcloud sql instances delete my-instance"
echo ""

# IAM
echo "9. IAM operations:"
echo "   gcloud iam service-accounts list      # List service accounts"
echo "   gcloud iam service-accounts create my-sa --display-name='My Service Account'"
echo "   gcloud projects add-iam-policy-binding PROJECT_ID --member='serviceAccount:my-sa@PROJECT_ID.iam.gserviceaccount.com' --role='roles/viewer'"
echo ""

# Monitoring and Logging
echo "10. Monitoring operations:"
echo "    gcloud logging logs list              # List logs"
echo "    gcloud logging read 'resource.type=gce_instance' --limit=10"
echo "    gcloud monitoring dashboards list     # List monitoring dashboards"
echo ""

echo "Usage: Copy and run individual commands from above examples"
echo "Note: Replace PROJECT_ID and resource names with actual values"
EOF
		
		chmod +x "$gcloud_examples"
		log_success "gcloud examples script created at $gcloud_examples"
	fi
	
	# Create deployment script
	local deploy_script="$gcloud_samples/deploy-vm.sh"
	if [[ ! -f "$deploy_script" ]]; then
		cat > "$deploy_script" << 'EOF'
#!/bin/bash

# Google Cloud VM Deployment Script
# Deploys a simple VM using Deployment Manager

set -euo pipefail

DEPLOYMENT_NAME="sample-vm-deployment"
TEMPLATE_FILE="vm-deployment.yaml"
PROJECT_ID=$(gcloud config get-value project)

echo "Google Cloud VM Deployment"
echo "=========================="

# Check if authenticated
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | head -n1 >/dev/null; then
    echo "Please authenticate with Google Cloud first:"
    echo "gcloud auth login"
    exit 1
fi

# Check if project is set
if [[ -z "$PROJECT_ID" || "$PROJECT_ID" == "(unset)" ]]; then
    echo "Please set a default project:"
    echo "gcloud config set project YOUR_PROJECT_ID"
    exit 1
fi

echo "Current project: $PROJECT_ID"
echo ""

echo "Creating deployment: $DEPLOYMENT_NAME"
gcloud deployment-manager deployments create "$DEPLOYMENT_NAME" \
    --config="$TEMPLATE_FILE" \
    --description="Sample VM deployment"

echo ""
echo "Deployment created successfully!"
echo "VM instance: sample-vm"
echo "Zone: us-central1-a"
echo ""

echo "To connect to the VM:"
echo "gcloud compute ssh sample-vm --zone=us-central1-a"
echo ""

echo "To clean up resources:"
echo "gcloud deployment-manager deployments delete $DEPLOYMENT_NAME"
EOF
		
		chmod +x "$deploy_script"
		log_success "Deployment script created at $deploy_script"
	fi
	
	# Create README
	local readme="$gcloud_samples/README.md"
	if [[ ! -f "$readme" ]]; then
		cat > "$readme" << 'EOF'
# Google Cloud SDK Examples

Sample configurations and scripts for Google Cloud Platform operations.

## Files

- **vm-deployment.yaml** - Deployment Manager template for a VM
- **gcloud-examples.sh** - Common gcloud commands reference
- **deploy-vm.sh** - Script to deploy the sample VM

## Getting Started

1. Authenticate with Google Cloud:
   ```bash
   gcloud auth login
   ```

2. Set your default project:
   ```bash
   gcloud config set project YOUR_PROJECT_ID
   ```

3. Run the deployment script:
   ```bash
   ./deploy-vm.sh
   ```

## Common Commands

```bash
# Authentication
gcloud auth login
gcloud auth application-default login
gcloud auth list

# Project management
gcloud projects list
gcloud config set project PROJECT_ID
gcloud config get-value project

# Compute Engine
gcloud compute instances list
gcloud compute instances create my-vm --zone=us-central1-a
gcloud compute ssh my-vm --zone=us-central1-a

# Cloud Storage
gsutil ls
gsutil mb gs://my-bucket
gsutil cp file.txt gs://my-bucket/

# Kubernetes
gcloud container clusters list
gcloud container clusters create my-cluster
kubectl get nodes
```

## Configuration

- Configuration directory: ~/.config/gcloud/
- Current settings: `gcloud config list`
- Set defaults: `gcloud config set compute/zone us-central1-a`

## Components

List installed components:
```bash
gcloud components list
```

Install component:
```bash
gcloud components install COMPONENT_NAME
```

Update components:
```bash
gcloud components update
```

## Useful Resources

- [Google Cloud SDK Documentation](https://cloud.google.com/sdk/docs)
- [gcloud Command Reference](https://cloud.google.com/sdk/gcloud/reference)
- [Deployment Manager Templates](https://cloud.google.com/deployment-manager/docs/configuration)
EOF
		
		log_success "README created at $readme"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating Google Cloud SDK aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for Google Cloud SDK
	local gcloud_aliases="
# Google Cloud SDK Aliases
alias gclogin='gcloud auth login'
alias gclogout='gcloud auth revoke --all'
alias gcauth='gcloud auth list'
alias gcproject='gcloud config get-value project'
alias gcprojects='gcloud projects list'
alias gcsetproject='gcloud config set project'
alias gcinstances='gcloud compute instances list'
alias gcclusters='gcloud container clusters list'
alias gcfunctions='gcloud functions list'
alias gcsql='gcloud sql instances list'
alias gcbuckets='gsutil ls'
alias gcconfig='gcloud config list'
alias gcinfo='gcloud info'
alias gcversion='gcloud version'
alias gcsamples='cd ~/gcloud-samples'
alias gcdeploy='cd ~/gcloud-samples && ./deploy-vm.sh'
alias k='kubectl'
alias kget='kubectl get'
alias kdesc='kubectl describe'
alias klogs='kubectl logs'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "Google Cloud SDK Aliases" "$alias_file"; then
			echo "$gcloud_aliases" >> "$alias_file"
		fi
	else
		echo "$gcloud_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "Google Cloud SDK aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying Google Cloud SDK installation"
	
	if command -v gcloud >/dev/null 2>&1; then
		log_success "Google Cloud SDK installed successfully!"
		echo "  Version: $(gcloud --version | head -n1)"
		echo "  Configuration: ~/.config/gcloud/"
		
		# Show installed components
		local component_count
		component_count=$(gcloud components list --format="value(id)" | wc -l)
		echo "  Components: $component_count installed"
		
		if command -v kubectl >/dev/null 2>&1; then
			echo "  kubectl: $(kubectl version --client --short 2>/dev/null || echo 'Available')"
		fi
		
		return 0
	else
		log_error "Google Cloud SDK installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

Google Cloud SDK Usage:
======================

Authentication:
  gcloud auth login           Login to Google Cloud (interactive)
  gcloud auth list            List authenticated accounts
  gcloud auth revoke          Revoke authentication

Project Management:
  gcloud projects list        List all projects
  gcloud config set project  Set default project
  gcloud config get-value project  Get current project

Compute Engine:
  gcloud compute instances list     List VM instances
  gcloud compute instances create   Create VM instance
  gcloud compute ssh               SSH to VM instance

Kubernetes:
  gcloud container clusters list   List GKE clusters
  gcloud container clusters create Create GKE cluster
  kubectl get nodes               List cluster nodes

Cloud Storage:
  gsutil ls                   List buckets
  gsutil mb gs://bucket       Create bucket
  gsutil cp file gs://bucket  Upload file

Configuration:
  gcloud config list          Show current configuration
  gcloud config set           Set configuration values
  gcloud components list      List installed components
  gcloud components install   Install component

Useful Aliases:
  gclogin                     gcloud auth login
  gcproject                   Show current project
  gcinstances                 List VM instances
  gcclusters                  List GKE clusters
  gcsamples                   Go to sample projects
  gcdeploy                    Deploy sample VM
  k                          kubectl shortcut

Sample Projects:
  ~/gcloud-samples/           Sample templates and scripts

Configuration Files:
  ~/.config/gcloud/           Google Cloud SDK configuration

For more information: https://cloud.google.com/sdk/docs

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_gcloudsdk_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure Google Cloud SDK
	install_gcloudsdk
	configure_gcloudsdk
	install_gcloud_components
	
	# Create sample configurations and aliases
	create_sample_configs
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "Use 'gcloud auth login' to authenticate with Google Cloud"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
