import subprocess
import os

commits = [
    ("5b3dc13", "feat: initial repository setup", "Established the baseline project structure for system automation."),
    ("954644d", "feat: add vagrant box update alias", "Introduced 'vupdate' alias to streamline Vagrant environment maintenance."),
    ("9fc9cf1", "fix: update docker installation script", "Corrected Docker installation procedures for improved stability."),
    ("7781e8e", "fix: update rvm installation script", "Updated Ruby Version Manager setup logic."),
    ("ecb1df7", "fix: update main installation entrypoint", "Refined the primary install.sh script for better error handling."),
    ("af72958", "feat: add additional system tools", "Expanded the toolset with new utility modules."),
    ("157efd1", "chore: apply multiple system improvements", "General performance and reliability enhancements across all scripts."),
    ("e677343", "feat: add php-curl module support", "Enabled PHP cURL extension installation in the web module."),
    ("3d6c268", "feat: add strapi and mongodb support", "Integrated Strapi CMS and MongoDB database installers."),
    ("4b4fce3", "chore: fix versioning metadata", "Standardized version tracking files."),
    ("a88bc3b", "docs: update project readme", "Comprehensive update to the main documentation."),
    ("14e052f", "chore: improve debugging output", "Enhanced log verbosity for troubleshooting installation failures."),
    ("76e20e0", "chore: general code cleanup and refresh", "Refactored code for better readability and maintainability."),
    ("57d702a", "feat: allow editing settings in main script", "Integrated configuration editing directly into the primary execution flow."),
    ("64e5ee5", "chore: project-wide maintenance and refresh", "Synchronized all modules with latest system standards."),
    ("3e408ec", "chore: final project refresh changes", "Completed the transition to the updated project structure."),
    ("77464c2", "feat: implement localtunnel support", "Added support for exposing local services via localtunnel."),
    ("8dbac13", "refactor: restructure installation logic", "Major internal refactoring of the installation engine."),
    ("516448b", "chore: ensure dependency resolution works", "Validated the automated dependency management system."),
    ("0acb399", "feat: improve localtunnel and install scripts", "Polished the localtunnel module and main installer."),
    ("029fdb2", "fix: update installation entrypoint", "Minor fixes to the main installation script."),
    ("783620e", "chore: minor maintenance fix", "Internal cleanup and small bug fixes."),
    ("a58e5f4", "chore: system cleanup", "Removed deprecated scripts and artifacts."),
    ("95637c3", "chore: internal script updates", "Routine maintenance of module scripts."),
    ("0dbad04", "chore: miscellaneous improvements", "Small tweaks to improve user experience."),
    ("03ae492", "chore: baseline updates", "Updated baseline configurations."),
    ("8864874", "fix: update docker module script", "Brought Docker installation script up to date."),
    ("44d6e8c", "chore: apply general system improvements", "Various small improvements to script efficiency."),
    ("779f414", "fix: update main entrypoint script", "Ensured main.sh is fully compatible with latest Linux distros."),
    ("a445997", "chore: update gitignore rules", "Added more exhaustive exclusion rules for system and build files."),
    ("af68a56", "feat: implement X11 server support", "Added modules for X11 graphical forwarding support."),
    ("8fbfc32", "feat: add RStudio and improve bashrc documentation", "Integrated RStudio installer and documented .bashrc modifications."),
    ("265d89e", "feat: implement powershell, shfmt and windows fresh install", "Major expansion for Windows support and script formatting tools."),
    ("f8f10d0", "feat: expand yarn, pip and windows support", "Enhanced package manager integration for Node and Python."),
    ("1890b7d", "chore: general repository update", "Synchronized all project components."),
    ("dc07c4a", "chore: maintenance update 1", "Scheduled internal maintenance."),
    ("719b431", "chore: maintenance update 2", "Continuous integration tweaks."),
    ("3d92e40", "chore: maintenance update 3", "Security and stability patches."),
    ("2055c8f", "fix: update main shell entrypoint", "Resolved execution issues in the main shell script."),
    ("da6f175", "chore: maintenance update 4", "Codebase hygiene and linting."),
    ("4c9a239", "chore: maintenance update 5", "Updated external dependency URLs."),
    ("5554f93", "chore: maintenance update 6", "Minor logic corrections."),
    ("3dbbbcd", "chore: maintenance update 7", "Final polish before monorepo transition."),
    ("5456244", "chore: update version metadata", "Updated the central version registry to reflect the latest release state."),
    ("c14dad9", "chore: minor updates and maintenance", "Internal maintenance and small fixes across various scripts."),
    ("d265724", "docs: summarize paths and directory structure", "Updated documentation to include a high-level summary of the project's file paths and organization."),
    ("b2b3561", "feat: add Lepton installation script", "Introduced a new installation module for Lepton, a lean GitHub Gist client."),
    ("ddcda50", "chore: update kubectl version to 1.48.8", "Bumped the Kubernetes CLI (kubectl) version to ensure compatibility with modern clusters."),
    ("ab8d159", "fix: resolve powershell script errors and configuration inconsistencies", "Fixed various glitches in PowerShell scripts and corrected erroneous configurations in the bootstrap setup."),
    ("c823b73", "chore: bump version numbers in bootstrap configuration", "Updated the versioning data in bootstrap/version.json to maintain accurate release tracking."),
    ("a8e895b", "feat: implement initial bootstrap and program installers", "Added the primary installation logic, including: Settings and bootstrap JSON files, utility library for cross-platform installers, and core program installation scripts."),
    ("fdc0c9d", "feat: expand installer library and technical documentation", "Massive expansion of the programs library with over 30 new installation scripts."),
    ("f3331eb", "feat: restructure repository into a professional Turborepo monorepo", "Comprehensive reorganization of the dotfiles ecosystem to support cross-platform modularity.")
]

def run(cmd):
    return subprocess.check_output(cmd, shell=True).decode().strip()

# 1. Start from orphan branch
print("Creating orphan branch...")
run("git checkout --orphan total-rewrite")
run("git rm -rf .")

# 2. Iterate and reconstruct
for hash_val, subject, body in commits:
    print(f"Applying {hash_val} as {subject}...")
    run(f"git checkout {hash_val} -- .")
    msg = f"{subject}\n\n{body}"
    with open(".git_msg", "w") as f:
        f.write(msg)
    run("git add .")
    run("git -c commit.gpgsign=false commit -F .git_msg")

# 3. Finalize
print("Finalizing history...")
run("git checkout master")
run("git reset --hard total-rewrite")
run("git branch -D total-rewrite")
os.remove(".git_msg")
print("DONE")
