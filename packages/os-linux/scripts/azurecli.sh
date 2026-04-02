#!/bin/bash

# Azure CLI Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="Azure CLI"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_azurecli_version() {
	azurecli_version=$(get_json_value "azurecli")
	if [[ -z "$azurecli_version" || "$azurecli_version" == "null" ]]; then
		azurecli_version="2.69.0"
	fi
	echo "$azurecli_version"
}

# Check if Azure CLI is already installed
check_azurecli_installation() {
	if command -v az >/dev/null 2>&1; then
		log_warning "Azure CLI is already installed"
		az --version | head -n1
		return 0
	fi
	return 1
}

# Install Azure CLI
install_azurecli() {
	log_step "Installing Azure CLI"
	
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Install prerequisites
			sudo apt-get update
			sudo apt-get install -y ca-certificates curl apt-transport-https lsb-release gnupg
			
			# Add Microsoft signing key
			curl -sLS https://packages.microsoft.com/keys/microsoft.asc | \
				gpg --dearmor | \
				sudo tee /etc/apt/keyrings/microsoft.gpg > /dev/null
			sudo chmod go+r /etc/apt/keyrings/microsoft.gpg
			
			# Add Azure CLI repository
			local release_name
			release_name=$(lsb_release -cs)
			echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/microsoft.gpg] https://packages.microsoft.com/repos/azure-cli/ $release_name main" | \
				sudo tee /etc/apt/sources.list.d/azure-cli.list
			
			# Update package list and install
			sudo apt-get update
			sudo apt-get install -y azure-cli
			;;
		yay|pacman)
			# Install from AUR or official repositories
			if command -v yay >/dev/null 2>&1; then
				yay -S --noconfirm azure-cli
			else
				sudo pacman -S --noconfirm azure-cli
			fi
			;;
		dnf)
			# Add Microsoft repository
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			sudo dnf install -y https://packages.microsoft.com/config/rhel/9/packages-microsoft-prod.rpm
			sudo dnf install -y azure-cli
			;;
		zypper)
			# Add Microsoft repository
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			sudo zypper addrepo --name 'Azure CLI' --check https://packages.microsoft.com/yumrepos/azure-cli azure-cli
			sudo zypper install -y --from azure-cli azure-cli
			;;
		brew)
			# Install Azure CLI via Homebrew
			brew install azure-cli
			;;
		*)
			log_warning "Package manager not supported, attempting installation script"
			install_azurecli_script
			;;
	esac
	
	log_success "Azure CLI installed successfully"
}

# Install Azure CLI using installation script (fallback method)
install_azurecli_script() {
	log_step "Installing Azure CLI using installation script"
	
	# Download and run Microsoft's installation script
	curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
	
	log_success "Azure CLI script installation completed"
}

# Configure Azure CLI
configure_azurecli() {
	log_step "Configuring Azure CLI"
	
	# Create Azure configuration directory
	local azure_config_dir="$HOME/.azure"
	mkdir -p "$azure_config_dir"
	
	# Configure default settings
	az configure --defaults location=eastus
	az configure --defaults group=""
	
	# Enable auto-install of extensions
	az config set extension.use_dynamic_install=yes_without_prompt
	
	# Configure output format (table is more readable for interactive use)
	az config set core.output=table
	
	# Disable telemetry collection for privacy
	az config set core.collect_telemetry=false
	
	log_success "Azure CLI configured with sensible defaults"
}

# Install useful Azure CLI extensions
install_azure_extensions() {
	log_step "Installing useful Azure CLI extensions"
	
	# Essential extensions
	local extensions=(
		"azure-devops"          # Azure DevOps integration
		"application-insights"  # Application Insights management
		"storage-preview"       # Azure Storage preview features
		"webapp"               # Azure Web Apps enhanced features
		"containerapp"         # Azure Container Apps
		"k8s-extension"        # Kubernetes cluster extensions
		"aks-preview"          # AKS preview features
		"resource-graph"       # Azure Resource Graph queries
		"account"              # Account management
		"monitor"              # Azure Monitor integration
	)
	
	for extension in "${extensions[@]}"; do
		if ! az extension list --query "[?name=='$extension']" --output tsv | grep -q "$extension"; then
			log_step "Installing extension: $extension"
			az extension add --name "$extension" || log_warning "Failed to install $extension"
		fi
	done
	
	log_success "Azure CLI extensions installed"
}

# Create sample Azure configurations
create_sample_configs() {
	log_step "Creating sample Azure configurations"
	
	local azure_samples="$HOME/azure-samples"
	mkdir -p "$azure_samples"
	
	# Create ARM template example
	local arm_template="$azure_samples/simple-webapp.json"
	if [[ ! -f "$arm_template" ]]; then
		cat > "$arm_template" << 'EOF'
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
        "webAppName": {
            "type": "string",
            "defaultValue": "[concat('webApp-', uniqueString(resourceGroup().id))]",
            "metadata": {
                "description": "Web app name."
            },
            "minLength": 2
        },
        "location": {
            "type": "string",
            "defaultValue": "[resourceGroup().location]",
            "metadata": {
                "description": "Location for all resources."
            }
        },
        "sku": {
            "type": "string",
            "defaultValue": "F1",
            "metadata": {
                "description": "The SKU of App Service Plan."
            }
        }
    },
    "variables": {
        "appServicePlanName": "[concat('AppServicePlan-', parameters('webAppName'))]"
    },
    "resources": [
        {
            "type": "Microsoft.Web/serverfarms",
            "apiVersion": "2020-06-01",
            "name": "[variables('appServicePlanName')]",
            "location": "[parameters('location')]",
            "sku": {
                "name": "[parameters('sku')]"
            }
        },
        {
            "type": "Microsoft.Web/sites",
            "apiVersion": "2020-06-01",
            "name": "[parameters('webAppName')]",
            "location": "[parameters('location')]",
            "dependsOn": [
                "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]"
            ],
            "properties": {
                "serverFarmId": "[resourceId('Microsoft.Web/serverfarms', variables('appServicePlanName'))]"
            }
        }
    ],
    "outputs": {
        "webAppURL": {
            "type": "string",
            "value": "[concat('https://', parameters('webAppName'), '.azurewebsites.net')]"
        }
    }
}
EOF
		log_success "ARM template example created at $arm_template"
	fi
	
	# Create Azure CLI script examples
	local cli_scripts="$azure_samples/cli-examples.sh"
	if [[ ! -f "$cli_scripts" ]]; then
		cat > "$cli_scripts" << 'EOF'
#!/bin/bash

# Azure CLI Examples Script
# Common Azure CLI commands for daily operations

set -euo pipefail

echo "Azure CLI Examples"
echo "=================="

# Login (interactive)
echo "1. Login to Azure:"
echo "   az login"
echo ""

# List subscriptions
echo "2. List subscriptions:"
echo "   az account list --output table"
echo ""

# Set default subscription
echo "3. Set default subscription:"
echo "   az account set --subscription 'Your Subscription Name'"
echo ""

# Resource Groups
echo "4. Resource Group operations:"
echo "   az group create --name myResourceGroup --location eastus"
echo "   az group list --output table"
echo "   az group delete --name myResourceGroup --yes --no-wait"
echo ""

# Storage Account
echo "5. Storage Account operations:"
echo "   az storage account create --name mystorageaccount --resource-group myResourceGroup --location eastus --sku Standard_LRS"
echo "   az storage account list --output table"
echo "   az storage account show --name mystorageaccount --resource-group myResourceGroup"
echo ""

# Virtual Machines
echo "6. Virtual Machine operations:"
echo "   az vm create --resource-group myResourceGroup --name myVM --image Ubuntu2204 --admin-username azureuser --generate-ssh-keys"
echo "   az vm list --output table"
echo "   az vm start --resource-group myResourceGroup --name myVM"
echo "   az vm stop --resource-group myResourceGroup --name myVM"
echo ""

# Web Apps
echo "7. Web App operations:"
echo "   az appservice plan create --name myAppServicePlan --resource-group myResourceGroup --sku F1"
echo "   az webapp create --resource-group myResourceGroup --plan myAppServicePlan --name myUniqueWebApp"
echo "   az webapp list --output table"
echo ""

# Container Instances
echo "8. Container Instance operations:"
echo "   az container create --resource-group myResourceGroup --name mycontainer --image mcr.microsoft.com/azuredocs/aci-helloworld --dns-name-label mycontainer --ports 80"
echo "   az container list --output table"
echo "   az container show --resource-group myResourceGroup --name mycontainer"
echo ""

# Azure Functions
echo "9. Azure Functions operations:"
echo "   az functionapp create --resource-group myResourceGroup --consumption-plan-location eastus --runtime node --runtime-version 18 --functions-version 4 --name myFunctionApp --storage-account mystorageaccount"
echo "   az functionapp list --output table"
echo ""

# Monitoring and Logs
echo "10. Monitoring operations:"
echo "    az monitor activity-log list --max-events 10"
echo "    az monitor metrics list --resource /subscriptions/SUBSCRIPTION_ID/resourceGroups/myResourceGroup/providers/Microsoft.Compute/virtualMachines/myVM --metric 'Percentage CPU'"
echo ""

echo "Usage: Run individual commands from above examples"
echo "Note: Replace placeholders with actual names and IDs"
EOF
		
		chmod +x "$cli_scripts"
		log_success "CLI examples script created at $cli_scripts"
	fi
	
	# Create deployment script
	local deploy_script="$azure_samples/deploy-webapp.sh"
	if [[ ! -f "$deploy_script" ]]; then
		cat > "$deploy_script" << 'EOF'
#!/bin/bash

# Azure Web App Deployment Script
# Deploys a simple web app using ARM template

set -euo pipefail

RESOURCE_GROUP="webapp-demo-rg"
LOCATION="eastus"
TEMPLATE_FILE="simple-webapp.json"

echo "Azure Web App Deployment"
echo "======================="

# Check if logged in
if ! az account show >/dev/null 2>&1; then
    echo "Please login to Azure first:"
    echo "az login"
    exit 1
fi

echo "Current subscription:"
az account show --query "{Name:name, ID:id}" --output table

echo ""
echo "Creating resource group: $RESOURCE_GROUP"
az group create --name "$RESOURCE_GROUP" --location "$LOCATION" --output table

echo ""
echo "Deploying web app using ARM template..."
az deployment group create \
    --resource-group "$RESOURCE_GROUP" \
    --template-file "$TEMPLATE_FILE" \
    --parameters webAppName="demo-webapp-$(date +%s)" \
    --output table

echo ""
echo "Deployment completed!"
echo "Resource group: $RESOURCE_GROUP"
echo ""
echo "To clean up resources:"
echo "az group delete --name $RESOURCE_GROUP --yes --no-wait"
EOF
		
		chmod +x "$deploy_script"
		log_success "Deployment script created at $deploy_script"
	fi
	
	# Create README
	local readme="$azure_samples/README.md"
	if [[ ! -f "$readme" ]]; then
		cat > "$readme" << 'EOF'
# Azure CLI Examples

Sample configurations and scripts for Azure CLI operations.

## Files

- **simple-webapp.json** - ARM template for a basic web app
- **cli-examples.sh** - Common Azure CLI commands
- **deploy-webapp.sh** - Script to deploy the sample web app

## Getting Started

1. Login to Azure:
   ```bash
   az login
   ```

2. Set your default subscription:
   ```bash
   az account set --subscription "Your Subscription Name"
   ```

3. Run the deployment script:
   ```bash
   ./deploy-webapp.sh
   ```

## Common Commands

```bash
# Account and subscription management
az login
az account list
az account set --subscription "subscription-name"

# Resource group operations
az group create --name myRG --location eastus
az group list
az group delete --name myRG

# Quick resource deployment
az deployment group create --resource-group myRG --template-file template.json

# List all resources in subscription
az resource list --output table

# Get help for any command
az vm --help
az storage --help
```

## Configuration

- Configuration directory: ~/.azure/
- Current settings: `az configure --list-defaults`
- Set defaults: `az configure --defaults location=eastus group=myDefaultRG`

## Extensions

List installed extensions:
```bash
az extension list
```

Install extension:
```bash
az extension add --name extension-name
```

## Useful Resources

- [Azure CLI Documentation](https://docs.microsoft.com/en-us/cli/azure/)
- [Azure CLI Reference](https://docs.microsoft.com/en-us/cli/azure/reference-index)
- [ARM Template Reference](https://docs.microsoft.com/en-us/azure/templates/)
EOF
		
		log_success "README created at $readme"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating Azure CLI aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for Azure CLI
	local azure_aliases="
# Azure CLI Aliases
alias azlogin='az login'
alias azlogout='az logout'
alias azaccount='az account show'
alias azlist='az account list --output table'
alias azset='az account set --subscription'
alias azgroups='az group list --output table'
alias azvms='az vm list --output table'
alias azapps='az webapp list --output table'
alias azstorageaccounts='az storage account list --output table'
alias azresources='az resource list --output table'
alias azlocations='az account list-locations --output table'
alias azextensions='az extension list --output table'
alias azconfig='az configure --list-defaults'
alias azversion='az --version'
alias azsamples='cd ~/azure-samples'
alias azdeploy='cd ~/azure-samples && ./deploy-webapp.sh'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "Azure CLI Aliases" "$alias_file"; then
			echo "$azure_aliases" >> "$alias_file"
		fi
	else
		echo "$azure_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "Azure CLI aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying Azure CLI installation"
	
	if command -v az >/dev/null 2>&1; then
		log_success "Azure CLI installed successfully!"
		echo "  Version: $(az --version | head -n1)"
		echo "  Configuration: $HOME/.azure/"
		
		# Show installed extensions
		local extension_count
		extension_count=$(az extension list --query "length(@)" --output tsv 2>/dev/null || echo "0")
		echo "  Extensions: $extension_count installed"
		
		return 0
	else
		log_error "Azure CLI installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

Azure CLI Usage:
===============

Authentication:
  az login                    Login to Azure (interactive)
  az login --service-principal Login with service principal
  az logout                   Logout from Azure
  az account show             Show current account info
  az account list             List available subscriptions

Resource Management:
  az group create             Create resource group
  az group list               List resource groups
  az resource list            List all resources
  az deployment group create  Deploy ARM template

Common Operations:
  az vm create                Create virtual machine
  az webapp create            Create web application
  az storage account create   Create storage account
  az container create         Create container instance

Configuration:
  az configure                Interactive configuration
  az configure --defaults     Set default values
  az extension add            Install extension
  az extension list           List installed extensions

Useful Aliases:
  azlogin                     az login
  azaccount                   Show current account
  azgroups                    List resource groups
  azvms                       List virtual machines
  azsamples                   Go to sample projects
  azdeploy                    Deploy sample web app

Sample Projects:
  ~/azure-samples/            Sample ARM templates and scripts

Configuration Files:
  ~/.azure/                   Azure CLI configuration directory

For more information: https://docs.microsoft.com/en-us/cli/azure/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_azurecli_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure Azure CLI
	install_azurecli
	configure_azurecli
	install_azure_extensions
	
	# Create sample configurations and aliases
	create_sample_configs
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "Use 'az login' to authenticate with Azure"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
