cinst -y vscode

$Extensions = @(
    "aaron-bond.better-comments"
    "coenraads.bracket-pair-colorizer"
    "kamikillerto.vscode-colorize"
    "dbaeumer.vscode-eslint"
    "davidanson.vscode-markdownlint"
    "hookyqr.minify"
    "esbenp.prettier-vscode"
    "wallabyjs.quokka-vscode"
    "ms-vscode-remote.remote-containers"
    "ms-vscode-remote.remote-ssh"
    "ms-vscode-remote.remote-ssh-edit"
    "ms-vscode-remote.remote-ssh-explorer"
    "ms-vscode-remote.remote-wsl"
    "ms-vscode-remote.vscode-remote-extensionpack"
    "ms-vscode-remote.vscode-remote-extensionpack"
    "redhat.vscode-yaml"
)
        
ForEach ($Extension in $Extensions) {
    Write-Output "Instaling $Extension"
    code --install-extension $Extension
}

#code --install-extension EditorConfig.EditorConfig
#code --install-extension vscodevim.vim
#code --install-extension eamodio.gitlens
#code --install-extension gerane.Theme-Paraisodark
#code --install-extension PeterJausovec.vscode-docker
#code --install-extension ms-vscode.PowerShell
#code --install-extension christian-kohler.path-intellisense
#code --install-extension robertohuertasm.vscode-icons
#code --install-extension streetsidesoftware.code-spell-checker