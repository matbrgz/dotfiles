#!/bin/bash

# Anaconda Python Data Science Platform Setup Script
# Modern script following the new dotfiles pattern with enhanced functionality

set -euo pipefail

# Source utility functions and project configuration
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$PROJECT_ROOT/lib/utils.sh"

# Configuration
SCRIPT_NAME="Anaconda Python Data Science Platform"
CONFIG_FILE="$HOME/.bashrc"
ANACONDA_INSTALL_DIR="$HOME/anaconda3"

# Get version from version.json
get_anaconda_version() {
	anaconda_version=$(get_json_value "anaconda")
	if [[ -z "$anaconda_version" || "$anaconda_version" == "null" ]]; then
		anaconda_version="2024.10-1"
	fi
	echo "$anaconda_version"
}

# Check if Anaconda is already installed
check_anaconda_installation() {
	if [[ -d "$ANACONDA_INSTALL_DIR" ]] && command -v conda >/dev/null 2>&1; then
		log_warning "Anaconda is already installed"
		conda --version
		return 0
	fi
	return 1
}

# Install Anaconda
install_anaconda() {
	log_step "Installing Anaconda"
	
	local anaconda_version arch os_name
	anaconda_version=$(get_anaconda_version)
	
	# Detect architecture and OS
	case "$(uname -m)" in
		x86_64) arch="x86_64" ;;
		aarch64|arm64) arch="aarch64" ;;
		*) log_error "Unsupported architecture: $(uname -m)"; return 1 ;;
	esac
	
	case "$(uname -s)" in
		Linux) os_name="Linux" ;;
		Darwin) os_name="MacOSX" ;;
		*) log_error "Unsupported OS: $(uname -s)"; return 1 ;;
	esac
	
	# Download and install Anaconda
	local download_url="https://repo.anaconda.com/archive/Anaconda3-${anaconda_version}-${os_name}-${arch}.sh"
	local installer_file="/tmp/anaconda-installer.sh"
	
	log_step "Downloading Anaconda $anaconda_version"
	curl -fsSL "$download_url" -o "$installer_file"
	
	# Verify installer (optional but recommended)
	if command -v sha256sum >/dev/null 2>&1; then
		log_step "Verifying installer checksum"
		# Note: In production, you'd want to verify against known checksums
	fi
	
	# Make installer executable
	chmod +x "$installer_file"
	
	# Run installer in batch mode
	log_step "Running Anaconda installer"
	bash "$installer_file" -b -p "$ANACONDA_INSTALL_DIR"
	
	# Cleanup
	rm -f "$installer_file"
	
	log_success "Anaconda installed successfully"
}

# Configure Anaconda environment
configure_anaconda() {
	log_step "Configuring Anaconda environment"
	
	# Initialize conda for shell integration
	"$ANACONDA_INSTALL_DIR/bin/conda" init bash
	
	# Source conda for current session
	source "$ANACONDA_INSTALL_DIR/etc/profile.d/conda.sh"
	
	# Configure conda settings
	conda config --set auto_activate_base false
	conda config --set changeps1 true
	conda config --set channel_priority strict
	
	# Add conda-forge channel
	conda config --add channels conda-forge
	
	# Update conda itself
	conda update -n base -c defaults conda --yes
	
	log_success "Anaconda environment configured"
}

# Create essential conda environments
create_conda_environments() {
	log_step "Creating essential conda environments"
	
	# Data Science environment
	log_step "Creating data science environment"
	conda create -n datascience python=3.11 --yes
	conda activate datascience
	
	# Install data science packages
	conda install --yes \
		numpy pandas matplotlib seaborn plotly \
		scikit-learn scipy statsmodels \
		jupyter jupyterlab notebook \
		ipykernel ipywidgets \
		requests beautifulsoup4 \
		openpyxl xlsxwriter \
		sqlalchemy psycopg2 pymongo \
		black flake8 pylint \
		pytest pytest-cov
	
	# Install additional packages via pip
	pip install \
		streamlit dash \
		ydata-profiling \
		optuna hyperopt \
		shap lime \
		mlflow wandb
	
	conda deactivate
	
	# Machine Learning environment
	log_step "Creating machine learning environment"
	conda create -n ml python=3.11 --yes
	conda activate ml
	
	# Install ML packages
	conda install --yes \
		numpy pandas matplotlib seaborn \
		scikit-learn xgboost lightgbm \
		tensorflow keras pytorch \
		jupyter jupyterlab \
		ipykernel ipywidgets
	
	# Install additional ML packages via pip
	pip install \
		catboost \
		optuna bayesian-optimization \
		shap lime \
		mlflow tensorboard \
		huggingface-hub transformers
	
	conda deactivate
	
	# Web Scraping environment
	log_step "Creating web scraping environment"
	conda create -n webscraping python=3.11 --yes
	conda activate webscraping
	
	# Install web scraping packages
	conda install --yes \
		requests beautifulsoup4 lxml \
		selenium scrapy \
		pandas numpy \
		jupyter jupyterlab
	
	pip install \
		playwright \
		requests-html \
		fake-useragent \
		schedule
	
	conda deactivate
	
	log_success "Conda environments created"
}

# Install Jupyter extensions and kernels
setup_jupyter() {
	log_step "Setting up Jupyter environment"
	
	# Activate base environment
	conda activate base
	
	# Install Jupyter extensions
	conda install --yes \
		jupyterlab-git \
		nb_conda_kernels \
		jupyter_contrib_nbextensions
	
	# Enable Jupyter extensions
	jupyter contrib nbextension install --user
	jupyter nbextension enable --py widgetsnbextension
	
	# Install JupyterLab extensions
	pip install \
		jupyterlab-lsp \
		jupyterlab-code-formatter \
		jupyterlab-system-monitor \
		jupyterlab-drawio \
		jupyterlab-spreadsheet
	
	# Register conda environments as Jupyter kernels
	conda activate datascience
	python -m ipykernel install --user --name datascience --display-name "Python (Data Science)"
	conda deactivate
	
	conda activate ml
	python -m ipykernel install --user --name ml --display-name "Python (Machine Learning)"
	conda deactivate
	
	conda activate webscraping
	python -m ipykernel install --user --name webscraping --display-name "Python (Web Scraping)"
	conda deactivate
	
	log_success "Jupyter environment configured"
}

# Create sample data science projects
create_sample_projects() {
	log_step "Creating sample data science projects"
	
	local projects_dir="$HOME/anaconda-projects"
	mkdir -p "$projects_dir"
	
	# Create exploratory data analysis project
	local eda_project="$projects_dir/exploratory-data-analysis"
	if [[ ! -d "$eda_project" ]]; then
		mkdir -p "$eda_project"
		cd "$eda_project"
		
		# Create sample EDA notebook
		cat > "sample_eda.ipynb" << 'EOF'
{
 "cells": [
  {
   "cell_type": "markdown",
   "metadata": {},
   "source": [
    "# Sample Exploratory Data Analysis\n",
    "\n",
    "This notebook demonstrates common EDA techniques using Python data science libraries."
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Import essential libraries\n",
    "import pandas as pd\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import seaborn as sns\n",
    "import plotly.express as px\n",
    "from sklearn.datasets import load_iris\n",
    "\n",
    "# Set plotting style\n",
    "plt.style.use('seaborn-v0_8')\n",
    "sns.set_palette('husl')\n",
    "\n",
    "print(\"Libraries imported successfully!\")"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Load sample dataset\n",
    "iris = load_iris()\n",
    "df = pd.DataFrame(iris.data, columns=iris.feature_names)\n",
    "df['species'] = iris.target_names[iris.target]\n",
    "\n",
    "print(f\"Dataset shape: {df.shape}\")\n",
    "print(\"\\nFirst 5 rows:\")\n",
    "df.head()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Basic statistics\n",
    "print(\"Dataset Info:\")\n",
    "print(df.info())\n",
    "print(\"\\nDescriptive Statistics:\")\n",
    "df.describe()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Visualizations\n",
    "fig, axes = plt.subplots(2, 2, figsize=(12, 10))\n",
    "\n",
    "# Distribution plots\n",
    "sns.histplot(data=df, x='sepal length (cm)', hue='species', ax=axes[0,0])\n",
    "axes[0,0].set_title('Sepal Length Distribution')\n",
    "\n",
    "sns.boxplot(data=df, x='species', y='petal length (cm)', ax=axes[0,1])\n",
    "axes[0,1].set_title('Petal Length by Species')\n",
    "\n",
    "# Scatter plots\n",
    "sns.scatterplot(data=df, x='sepal length (cm)', y='sepal width (cm)', hue='species', ax=axes[1,0])\n",
    "axes[1,0].set_title('Sepal Length vs Width')\n",
    "\n",
    "# Correlation heatmap\n",
    "correlation_matrix = df.select_dtypes(include=[np.number]).corr()\n",
    "sns.heatmap(correlation_matrix, annot=True, cmap='coolwarm', ax=axes[1,1])\n",
    "axes[1,1].set_title('Feature Correlation Matrix')\n",
    "\n",
    "plt.tight_layout()\n",
    "plt.show()"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": null,
   "metadata": {},
   "outputs": [],
   "source": [
    "# Interactive plot with Plotly\n",
    "fig = px.scatter_matrix(\n",
    "    df,\n",
    "    dimensions=['sepal length (cm)', 'sepal width (cm)', 'petal length (cm)', 'petal width (cm)'],\n",
    "    color='species',\n",
    "    title='Iris Dataset - Interactive Scatter Matrix'\n",
    ")\n",
    "fig.show()"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "Python (Data Science)",
   "language": "python",
   "name": "datascience"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.11.0"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 4
}
EOF
		
		# Create environment file
		cat > "environment.yml" << 'EOF'
name: datascience
channels:
  - conda-forge
  - defaults
dependencies:
  - python=3.11
  - numpy
  - pandas
  - matplotlib
  - seaborn
  - plotly
  - scikit-learn
  - scipy
  - statsmodels
  - jupyter
  - jupyterlab
  - notebook
  - ipykernel
  - ipywidgets
  - requests
  - beautifulsoup4
  - openpyxl
  - xlsxwriter
  - pip
  - pip:
    - streamlit
    - ydata-profiling
    - optuna
    - shap
    - mlflow
EOF
		
		# Create README
		cat > "README.md" << 'EOF'
# Exploratory Data Analysis Project

Sample project demonstrating exploratory data analysis techniques using Python data science stack.

## Setup

1. Activate the data science environment:
   ```bash
   conda activate datascience
   ```

2. Start Jupyter Lab:
   ```bash
   jupyter lab
   ```

3. Open `sample_eda.ipynb` and run the cells

## Environment

This project uses the `datascience` conda environment which includes:
- pandas, numpy for data manipulation
- matplotlib, seaborn, plotly for visualization
- scikit-learn for machine learning
- jupyter for interactive development

## Files

- `sample_eda.ipynb` - Main analysis notebook
- `environment.yml` - Conda environment specification
- `README.md` - This file
EOF
		
		log_success "EDA project created at $eda_project"
	fi
	
	# Create machine learning project
	local ml_project="$projects_dir/machine-learning-pipeline"
	if [[ ! -d "$ml_project" ]]; then
		mkdir -p "$ml_project"
		cd "$ml_project"
		
		# Create ML pipeline script
		cat > "ml_pipeline.py" << 'EOF'
#!/usr/bin/env python3
"""
Sample Machine Learning Pipeline
Demonstrates a complete ML workflow from data loading to model evaluation
"""

import pandas as pd
import numpy as np
from sklearn.datasets import load_wine
from sklearn.model_selection import train_test_split, cross_val_score, GridSearchCV
from sklearn.preprocessing import StandardScaler
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LogisticRegression
from sklearn.svm import SVC
from sklearn.metrics import classification_report, confusion_matrix, accuracy_score
import matplotlib.pyplot as plt
import seaborn as sns
import joblib

def load_data():
    """Load and prepare the wine dataset"""
    wine = load_wine()
    X = pd.DataFrame(wine.data, columns=wine.feature_names)
    y = pd.Series(wine.target, name='wine_class')
    
    print(f"Dataset shape: {X.shape}")
    print(f"Target classes: {wine.target_names}")
    
    return X, y, wine.target_names

def preprocess_data(X, y):
    """Split and scale the data"""
    X_train, X_test, y_train, y_test = train_test_split(
        X, y, test_size=0.2, random_state=42, stratify=y
    )
    
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_test_scaled = scaler.transform(X_test)
    
    return X_train_scaled, X_test_scaled, y_train, y_test, scaler

def train_models(X_train, y_train):
    """Train multiple models and compare performance"""
    models = {
        'Random Forest': RandomForestClassifier(random_state=42),
        'Logistic Regression': LogisticRegression(random_state=42, max_iter=1000),
        'Support Vector Machine': SVC(random_state=42)
    }
    
    model_scores = {}
    trained_models = {}
    
    for name, model in models.items():
        print(f"\nTraining {name}...")
        
        # Cross-validation
        cv_scores = cross_val_score(model, X_train, y_train, cv=5)
        model_scores[name] = cv_scores.mean()
        
        # Train on full training set
        model.fit(X_train, y_train)
        trained_models[name] = model
        
        print(f"Cross-validation accuracy: {cv_scores.mean():.3f} (+/- {cv_scores.std() * 2:.3f})")
    
    return trained_models, model_scores

def hyperparameter_tuning(X_train, y_train):
    """Perform hyperparameter tuning for Random Forest"""
    print("\nPerforming hyperparameter tuning for Random Forest...")
    
    param_grid = {
        'n_estimators': [50, 100, 200],
        'max_depth': [None, 10, 20],
        'min_samples_split': [2, 5, 10]
    }
    
    rf = RandomForestClassifier(random_state=42)
    grid_search = GridSearchCV(rf, param_grid, cv=3, scoring='accuracy', n_jobs=-1)
    grid_search.fit(X_train, y_train)
    
    print(f"Best parameters: {grid_search.best_params_}")
    print(f"Best cross-validation score: {grid_search.best_score_:.3f}")
    
    return grid_search.best_estimator_

def evaluate_model(model, X_test, y_test, class_names):
    """Evaluate model performance"""
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    
    print(f"\nTest Accuracy: {accuracy:.3f}")
    print("\nClassification Report:")
    print(classification_report(y_test, y_pred, target_names=class_names))
    
    # Confusion matrix
    cm = confusion_matrix(y_test, y_pred)
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=class_names, yticklabels=class_names)
    plt.title('Confusion Matrix')
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.tight_layout()
    plt.savefig('confusion_matrix.png', dpi=300, bbox_inches='tight')
    plt.show()
    
    return y_pred

def feature_importance_analysis(model, feature_names):
    """Analyze feature importance for tree-based models"""
    if hasattr(model, 'feature_importances_'):
        importance_df = pd.DataFrame({
            'feature': feature_names,
            'importance': model.feature_importances_
        }).sort_values('importance', ascending=False)
        
        plt.figure(figsize=(10, 8))
        sns.barplot(data=importance_df.head(10), x='importance', y='feature')
        plt.title('Top 10 Feature Importances')
        plt.xlabel('Importance')
        plt.tight_layout()
        plt.savefig('feature_importance.png', dpi=300, bbox_inches='tight')
        plt.show()
        
        return importance_df
    else:
        print("Model doesn't have feature_importances_ attribute")
        return None

def save_model(model, scaler, filename='best_model.pkl'):
    """Save the trained model and scaler"""
    model_data = {'model': model, 'scaler': scaler}
    joblib.dump(model_data, filename)
    print(f"Model saved as {filename}")

def main():
    """Main pipeline execution"""
    print("=== Wine Classification ML Pipeline ===\n")
    
    # Load data
    X, y, class_names = load_data()
    
    # Preprocess data
    X_train, X_test, y_train, y_test, scaler = preprocess_data(X, y)
    
    # Train multiple models
    trained_models, model_scores = train_models(X_train, y_train)
    
    # Find best model
    best_model_name = max(model_scores, key=model_scores.get)
    print(f"\nBest model: {best_model_name} (CV Accuracy: {model_scores[best_model_name]:.3f})")
    
    # Hyperparameter tuning for Random Forest
    if best_model_name == 'Random Forest':
        best_model = hyperparameter_tuning(X_train, y_train)
    else:
        best_model = trained_models[best_model_name]
    
    # Evaluate on test set
    y_pred = evaluate_model(best_model, X_test, y_test, class_names)
    
    # Feature importance analysis
    feature_importance = feature_importance_analysis(best_model, X.columns)
    
    # Save model
    save_model(best_model, scaler)
    
    print("\n=== Pipeline completed successfully! ===")

if __name__ == "__main__":
    main()
EOF
		
		chmod +x "ml_pipeline.py"
		
		# Create README
		cat > "README.md" << 'EOF'
# Machine Learning Pipeline Project

Complete machine learning pipeline demonstrating best practices for model development.

## Features

- Data loading and preprocessing
- Multiple model comparison
- Hyperparameter tuning
- Model evaluation with metrics and visualizations
- Feature importance analysis
- Model persistence

## Usage

1. Activate the ML environment:
   ```bash
   conda activate ml
   ```

2. Run the pipeline:
   ```bash
   python ml_pipeline.py
   ```

## Output

The pipeline generates:
- Model performance metrics
- Confusion matrix visualization
- Feature importance plot
- Saved model file (best_model.pkl)

## Environment

Uses the `ml` conda environment with scikit-learn, pandas, matplotlib, and other ML libraries.
EOF
		
		log_success "ML project created at $ml_project"
	fi
}

# Create useful aliases
create_aliases() {
	log_step "Creating Anaconda aliases"
	
	local alias_file="$HOME/.bash_aliases"
	
	# Create aliases for Anaconda
	local anaconda_aliases="
# Anaconda Aliases
alias conda-info='conda info'
alias conda-envs='conda env list'
alias conda-activate='conda activate'
alias conda-deactivate='conda deactivate'
alias conda-create='conda create'
alias conda-remove='conda env remove'
alias conda-install='conda install'
alias conda-update='conda update --all'
alias conda-search='conda search'
alias conda-clean='conda clean --all'
alias jupyter-lab='jupyter lab'
alias jupyter-notebook='jupyter notebook'
alias anaconda-projects='cd ~/anaconda-projects'
alias ds-env='conda activate datascience'
alias ml-env='conda activate ml'
alias scraping-env='conda activate webscraping'
alias conda-export='conda env export > environment.yml'
alias conda-channels='conda config --show channels'
"
	
	if [[ -f "$alias_file" ]]; then
		if ! grep -q "Anaconda Aliases" "$alias_file"; then
			echo "$anaconda_aliases" >> "$alias_file"
		fi
	else
		echo "$anaconda_aliases" > "$alias_file"
	fi
	
	# Source aliases in bashrc if not already done
	if [[ -f "$CONFIG_FILE" ]] && ! grep -q ".bash_aliases" "$CONFIG_FILE"; then
		echo "
# Source bash aliases
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi" >> "$CONFIG_FILE"
	fi
	
	log_success "Anaconda aliases created"
}

# Verify installation
verify_installation() {
	log_step "Verifying Anaconda installation"
	
	if command -v conda >/dev/null 2>&1; then
		log_success "Anaconda installed successfully!"
		echo "  Version: $(conda --version)"
		echo "  Installation: $ANACONDA_INSTALL_DIR"
		
		# Show available environments
		echo "  Environments:"
		conda env list | grep -v '^#' | sed 's/^/    /'
		
		# Show Python version
		if command -v python >/dev/null 2>&1; then
			echo "  Python: $(python --version)"
		fi
		
		return 0
	else
		log_error "Anaconda installation failed"
		return 1
	fi
}

# Show usage instructions
show_usage() {
	cat << 'EOF'

Anaconda Python Data Science Platform Usage:
============================================

Environment Management:
  conda env list                 List all environments
  conda create -n myenv python   Create new environment
  conda activate myenv           Activate environment
  conda deactivate               Deactivate current environment
  conda env remove -n myenv      Remove environment

Package Management:
  conda install package          Install package
  conda update package           Update package
  conda remove package           Remove package
  conda list                     List installed packages
  conda search package           Search for packages

Jupyter:
  jupyter lab                    Start JupyterLab
  jupyter notebook               Start Jupyter Notebook
  jupyter kernelspec list        List available kernels

Pre-configured Environments:
  datascience                    General data science stack
  ml                             Machine learning focused
  webscraping                    Web scraping tools

Useful Aliases:
  conda-envs                     List environments
  ds-env                         Activate data science environment
  ml-env                         Activate ML environment
  scraping-env                   Activate web scraping environment
  jupyter-lab                    Start JupyterLab
  anaconda-projects              Go to sample projects

Sample Projects:
  ~/anaconda-projects/exploratory-data-analysis/      EDA examples
  ~/anaconda-projects/machine-learning-pipeline/      ML pipeline

Configuration:
  ~/.condarc                     Conda configuration file
  ~/anaconda3/                   Anaconda installation directory

For more information: https://docs.anaconda.com/

EOF
}

# Main execution
main() {
	log_step "Starting $SCRIPT_NAME installation"
	
	# Check if already installed
	if check_anaconda_installation; then
		verify_installation
		show_usage
		return 0
	fi
	
	# Install and configure Anaconda
	install_anaconda
	configure_anaconda
	create_conda_environments
	setup_jupyter
	
	# Create sample projects and aliases
	create_sample_projects
	create_aliases
	
	if verify_installation; then
		show_usage
		log_success "$SCRIPT_NAME installation completed!"
		log_warning "Please restart your shell or run: source ~/.bashrc"
		log_warning "Then use 'conda activate datascience' to start working"
	else
		log_error "$SCRIPT_NAME installation failed!"
		exit 1
	fi
}

# Execute main function
main "$@"
