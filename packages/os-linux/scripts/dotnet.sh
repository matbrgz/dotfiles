#!/bin/bash

# .NET Development Environment Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME=".NET Development Environment"
CONFIG_FILE="$HOME/.bashrc"

# Get version from version.json
get_dotnet_version() {
	dotnet_version=$(get_json_value "dotnet")
	if [[ -z "$dotnet_version" || "$dotnet_version" == "null" ]]; then
		dotnet_version="9.0.101"
	fi
	echo "$dotnet_version"
}

# Check if .NET is already installed
check_dotnet_installation() {
	if command -v dotnet >/dev/null 2>&1; then
		log_warning ".NET is already installed"
		dotnet --version
		return 0
	fi
	return 1
}

# Install .NET
install_dotnet() {
	log_step "Installing .NET"
	
	local dotnet_version
	dotnet_version=$(get_dotnet_version)
	local package_manager
	package_manager=$(detect_package_manager)
	
	case $package_manager in
		apt)
			# Install prerequisites
			sudo apt-get update
			sudo apt-get install -y wget apt-transport-https software-properties-common
			
			# Add Microsoft repository
			wget https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
			sudo dpkg -i packages-microsoft-prod.deb
			rm packages-microsoft-prod.deb
			
			# Update package list
			sudo apt-get update
			
			# Install .NET SDK
			sudo apt-get install -y dotnet-sdk-9.0
			;;
		yay|pacman)
			# Install from AUR or official repositories
			if command -v yay >/dev/null 2>&1; then
				yay -S --noconfirm dotnet-sdk
			else
				sudo pacman -S --noconfirm dotnet-sdk
			fi
			;;
		dnf)
			# Add Microsoft repository
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			sudo wget -O /etc/yum.repos.d/microsoft-prod.repo https://packages.microsoft.com/config/fedora/$(rpm -E %fedora)/prod.repo
			
			# Install .NET SDK
			sudo dnf install -y dotnet-sdk-9.0
			;;
		zypper)
			# Add Microsoft repository
			sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
			sudo zypper addrepo https://packages.microsoft.com/config/opensuse/15/prod.repo
			sudo zypper refresh
			
			# Install .NET SDK
			sudo zypper install -y dotnet-sdk-9.0
			;;
		brew)
			# Install .NET via Homebrew
			brew install --cask dotnet
			;;
		*)
			log_warning "Package manager not supported, attempting script installation"
			install_dotnet_script
			;;
	esac
	
	log_success ".NET installed successfully"
}

# Install .NET using Microsoft installation script (fallback method)
install_dotnet_script() {
	log_step "Installing .NET using installation script"
	
	# Download and run Microsoft's installation script
	curl -fsSL https://dot.net/v1/dotnet-install.sh -o dotnet-install.sh
	chmod +x dotnet-install.sh
	
	# Install latest LTS version
	./dotnet-install.sh --channel LTS --install-dir "$HOME/.dotnet"
	
	# Add to PATH
	export PATH="$HOME/.dotnet:$PATH"
	echo 'export PATH="$HOME/.dotnet:$PATH"' >> "$CONFIG_FILE"
	
	# Cleanup
	rm dotnet-install.sh
	
	log_success ".NET script installation completed"
}

# Configure .NET environment
configure_dotnet() {
	log_step "Configuring .NET environment"
	
	# Create .NET configuration directory
	local dotnet_config_dir="$HOME/.nuget"
	mkdir -p "$dotnet_config_dir"
	
	# Configure NuGet sources
	dotnet nuget add source https://api.nuget.org/v3/index.json --name "NuGet official package source" || true
	
	# Configure telemetry (disable for privacy)
	export DOTNET_CLI_TELEMETRY_OPTOUT=1
	if ! grep -q "DOTNET_CLI_TELEMETRY_OPTOUT" "$CONFIG_FILE" 2>/dev/null; then
		echo 'export DOTNET_CLI_TELEMETRY_OPTOUT=1' >> "$CONFIG_FILE"
	fi
	
	# Configure to use invariant mode for globalization (optional performance improvement)
	export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1
	if ! grep -q "DOTNET_SYSTEM_GLOBALIZATION_INVARIANT" "$CONFIG_FILE" 2>/dev/null; then
		echo 'export DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=1' >> "$CONFIG_FILE"
	fi
	
	log_success ".NET environment configured"
}

# Install useful .NET tools
install_dotnet_tools() {
	log_step "Installing useful .NET tools"
	
	# Global tools to install
	local tools=(
		"dotnet-ef"                 # Entity Framework Core tools
		"dotnet-aspnet-codegenerator" # ASP.NET Core scaffolding
		"dotnet-dump"               # Memory dump tool
		"dotnet-trace"              # Performance tracing
		"dotnet-counters"           # Performance counters
		"Microsoft.Web.LibraryManager.Cli" # LibMan CLI
		"dotnet-reportgenerator-globaltool" # Code coverage reports
		"dotnet-stryker"            # Mutation testing
		"upgrade-assistant"         # .NET upgrade assistant
	)
	
	for tool in "${tools[@]}"; do
		if ! dotnet tool list -g | grep -q "$tool"; then
			log_step "Installing tool: $tool"
			dotnet tool install --global "$tool" || log_warning "Failed to install $tool"
		fi
	done
	
	log_success ".NET tools installed"
}

# Create sample .NET projects
create_sample_projects() {
	log_step "Creating sample .NET projects"
	
	local projects_dir="$HOME/dotnet-projects"
	mkdir -p "$projects_dir"
	
	# Create Web API project
	local webapi_project="$projects_dir/sample-webapi"
	if [[ ! -d "$webapi_project" ]]; then
		mkdir -p "$webapi_project"
		cd "$webapi_project"
		
		# Create Web API
		dotnet new webapi -n SampleWebApi --use-controllers
		cd SampleWebApi
		
		# Add useful packages
		dotnet add package Swashbuckle.AspNetCore
		dotnet add package Serilog.AspNetCore
		dotnet add package Microsoft.EntityFrameworkCore.InMemory
		dotnet add package AutoMapper.Extensions.Microsoft.DependencyInjection
		
		# Create sample controller
		cat > Controllers/ProductsController.cs << 'EOF'
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;

namespace SampleWebApi.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProductsController : ControllerBase
{
    private static readonly List<Product> Products = new()
    {
        new Product { Id = 1, Name = "Laptop", Price = 999.99m, Category = "Electronics" },
        new Product { Id = 2, Name = "Coffee Mug", Price = 12.99m, Category = "Kitchen" },
        new Product { Id = 3, Name = "Book", Price = 29.99m, Category = "Education" }
    };

    [HttpGet]
    public ActionResult<IEnumerable<Product>> Get()
    {
        return Ok(Products);
    }

    [HttpGet("{id}")]
    public ActionResult<Product> Get(int id)
    {
        var product = Products.FirstOrDefault(p => p.Id == id);
        return product == null ? NotFound() : Ok(product);
    }

    [HttpPost]
    public ActionResult<Product> Post([FromBody] Product product)
    {
        product.Id = Products.Max(p => p.Id) + 1;
        Products.Add(product);
        return CreatedAtAction(nameof(Get), new { id = product.Id }, product);
    }

    [HttpPut("{id}")]
    public IActionResult Put(int id, [FromBody] Product product)
    {
        var existingProduct = Products.FirstOrDefault(p => p.Id == id);
        if (existingProduct == null) return NotFound();

        existingProduct.Name = product.Name;
        existingProduct.Price = product.Price;
        existingProduct.Category = product.Category;
        
        return NoContent();
    }

    [HttpDelete("{id}")]
    public IActionResult Delete(int id)
    {
        var product = Products.FirstOrDefault(p => p.Id == id);
        if (product == null) return NotFound();

        Products.Remove(product);
        return NoContent();
    }
}

public class Product
{
    public int Id { get; set; }
    
    [Required]
    public string Name { get; set; } = string.Empty;
    
    [Range(0.01, double.MaxValue)]
    public decimal Price { get; set; }
    
    [Required]
    public string Category { get; set; } = string.Empty;
}
EOF
		
		# Create README for Web API
		cat > README.md << 'EOF'
# Sample .NET Web API

A simple REST API built with ASP.NET Core demonstrating CRUD operations.

## Features

- RESTful API endpoints
- Swagger/OpenAPI documentation
- Data validation
- In-memory data storage
- Structured logging with Serilog

## Usage

```bash
# Run the API
dotnet run

# Access Swagger UI
# http://localhost:5000/swagger

# Test endpoints
curl http://localhost:5000/api/products
curl http://localhost:5000/api/products/1
```

## Endpoints

- GET /api/products - Get all products
- GET /api/products/{id} - Get product by ID
- POST /api/products - Create new product
- PUT /api/products/{id} - Update product
- DELETE /api/products/{id} - Delete product
EOF
		
		cd ..
		log_success "Web API project created at $webapi_project"
	fi
	
	# Create Console App project
	local console_project="$projects_dir/sample-console"
	if [[ ! -d "$console_project" ]]; then
		mkdir -p "$console_project"
		cd "$console_project"
		
		# Create Console App
		dotnet new console -n SampleConsole
		cd SampleConsole
		
		# Add useful packages
		dotnet add package Microsoft.Extensions.Hosting
		dotnet add package Microsoft.Extensions.DependencyInjection
		dotnet add package Microsoft.Extensions.Configuration
		dotnet add package Serilog.Extensions.Hosting
		dotnet add package Newtonsoft.Json
		
		# Create sample application
		cat > Program.cs << 'EOF'
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using Newtonsoft.Json;

namespace SampleConsole;

class Program
{
    static async Task Main(string[] args)
    {
        // Build host with dependency injection
        var host = Host.CreateDefaultBuilder(args)
            .ConfigureServices((context, services) =>
            {
                services.AddScoped<IWeatherService, WeatherService>();
                services.AddScoped<App>();
            })
            .Build();

        // Run the application
        var app = host.Services.GetRequiredService<App>();
        await app.RunAsync();
    }
}

public class App
{
    private readonly IWeatherService _weatherService;
    private readonly ILogger<App> _logger;

    public App(IWeatherService weatherService, ILogger<App> logger)
    {
        _weatherService = weatherService;
        _logger = logger;
    }

    public async Task RunAsync()
    {
        _logger.LogInformation("Sample .NET Console Application Started");

        try
        {
            var weather = await _weatherService.GetWeatherAsync("New York");
            
            Console.WriteLine("Weather Information:");
            Console.WriteLine($"City: {weather.City}");
            Console.WriteLine($"Temperature: {weather.Temperature}°C");
            Console.WriteLine($"Description: {weather.Description}");
            Console.WriteLine($"Humidity: {weather.Humidity}%");

            _logger.LogInformation("Weather data retrieved successfully");
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error occurred while fetching weather data");
            Console.WriteLine("Error: Could not fetch weather data");
        }

        _logger.LogInformation("Application completed");
    }
}

public interface IWeatherService
{
    Task<WeatherInfo> GetWeatherAsync(string city);
}

public class WeatherService : IWeatherService
{
    private readonly ILogger<WeatherService> _logger;

    public WeatherService(ILogger<WeatherService> logger)
    {
        _logger = logger;
    }

    public async Task<WeatherInfo> GetWeatherAsync(string city)
    {
        _logger.LogInformation("Fetching weather for {City}", city);
        
        // Simulate API call delay
        await Task.Delay(1000);
        
        // Return mock data
        return new WeatherInfo
        {
            City = city,
            Temperature = Random.Shared.Next(-10, 35),
            Description = GetRandomDescription(),
            Humidity = Random.Shared.Next(30, 90)
        };
    }

    private static string GetRandomDescription()
    {
        var descriptions = new[] { "Sunny", "Cloudy", "Rainy", "Partly Cloudy", "Clear" };
        return descriptions[Random.Shared.Next(descriptions.Length)];
    }
}

public class WeatherInfo
{
    public string City { get; set; } = string.Empty;
    public int Temperature { get; set; }
    public string Description { get; set; } = string.Empty;
    public int Humidity { get; set; }
}
EOF
		
		# Create README for Console App
		cat > README.md << 'EOF'
# Sample .NET Console Application

A console application demonstrating dependency injection, logging, and async programming.

## Features

- Dependency injection with Microsoft.Extensions.DI
- Structured logging
- Async/await patterns
- Configuration management
- Service-oriented architecture

## Usage

```bash
# Run the application
dotnet run
```

## Architecture

- **Program.cs** - Entry point with host builder
- **App.cs** - Main application logic
- **WeatherService.cs** - Sample service with dependency injection
- **WeatherInfo.cs** - Data model
EOF
		
		cd ..
		log_success "Console app project created at $console_project"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating .NET aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for .NET
	local dotnet_aliases="
# .NET Aliases
alias dn='dotnet'
alias dnr='dotnet run'
alias dnb='dotnet build'
alias dnt='dotnet test'
alias dnc='dotnet clean'
alias dnp='dotnet publish'
alias dnw='dotnet watch'
alias dnnew='dotnet new'
alias dnadd='dotnet add'
alias dnrest='dotnet restore'
alias dnef='dotnet ef'
alias dntools='dotnet tool list -g'
alias dninfo='dotnet --info'
alias dnversion='dotnet --version'
alias dnlist='dotnet --list-sdks'
alias dnprojects='cd ~/dotnet-projects'
alias dnapi='cd ~/dotnet-projects/sample-webapi/SampleWebApi && dotnet run'
alias dnconsole='cd ~/dotnet-projects/sample-console/SampleConsole && dotnet run'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q ".NET Aliases" "$alias_file"; then
			echo "$dotnet_aliases" >> "$alias_file"
		fi
	else
		echo "$dotnet_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success ".NET aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying .NET installation"
	
	if command -v dotnet >/dev/null 2>&1; then
		log_success ".NET installed successfully!"
		echo "  Version: $(dotnet --version)"
		echo "  Runtime: $(dotnet --info | grep "Microsoft.NETCore.App" | head -n1 | xargs)"
		echo "  Global tools: $(dotnet tool list -g | wc -l) tools installed"
		
		# Show installed SDKs
		echo "  Installed SDKs:"
		dotnet --list-sdks | sed 's/^/    /'
		
		return 0
	else
		log_error ".NET installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

.NET Development Environment Usage:
==================================

Basic Commands:
  dotnet --version            Check .NET version
  dotnet --info               Show detailed info
  dotnet new                  Create new project
  dotnet build                Build project
  dotnet run                  Run project
  dotnet test                 Run tests

Project Management:
  dotnet new console          Create console app
  dotnet new webapi           Create Web API
  dotnet new mvc              Create MVC app
  dotnet new classlib         Create class library
  dotnet add package <name>   Add NuGet package
  dotnet restore              Restore dependencies

Global Tools:
  dotnet tool list -g         List global tools
  dotnet tool install -g <tool>  Install global tool
  dotnet ef                   Entity Framework Core CLI

Useful Aliases:
  dn                          dotnet
  dnr                         dotnet run
  dnb                         dotnet build
  dnt                         dotnet test
  dnprojects                  Go to .NET projects directory
  dnapi                       Run sample Web API
  dnconsole                   Run sample console app

Sample Projects:
  ~/dotnet-projects/sample-webapi/     REST API with Swagger
  ~/dotnet-projects/sample-console/    Console app with DI

Configuration:
  ~/.nuget/                   NuGet configuration
  DOTNET_CLI_TELEMETRY_OPTOUT Disable telemetry

For more information: https://docs.microsoft.com/en-us/dotnet/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_dotnet_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure .NET
	install_dotnet
	configure_dotnet
	install_dotnet_tools
	
	# Create sample projects and aliases
	create_sample_projects
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "You may need to restart your shell or run: source ~/.bashrc"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
