if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $GlobalStopWatch = New-Object System.Diagnostics.Stopwatch
    $GlobalStopWatch.Start()
    Write-Output "`n [ START ] Configuring System Run"
    $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
    Set-ExecutionPolicy RemoteSigned
    $ComputerName = Get-Random -InputObject "Turing", "Knuth", "Berners-Lee", "Torvalds", "Hopper", "Ritchie", "Stallman", "Gosling", "Church", "Dijkstra", "Cooper", "Gates", "Jobs", "Wozniak", "Zuckerberg", "Musk", "Nakamoto", "Dotcom", "Snowden", "Kruskal", "Neumann"
    $StopWatch.Stop()
    $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
    Write-Output " [ DONE ] Configuring System Run ... $StopWatchElapsed seconds`n"
    Write-Output " ( PRESS KEY '1' FOR EXPRESS INSTALL )
 ( PRESS KEY '2' FOR CUSTOM INSTALL )"
    $InstalationType = Read-Host -Prompt " Option"
    $DebugMode = Read-Host -Prompt "`n Enable Debug Mode (y/N)"
    if ($DebugMode -eq 'Y' -Or $DebugMode -eq 'y') {
    }
    $FirstRun = Read-Host -Prompt "`n First time runing script? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($FirstRun) -Or $FirstRun -eq 'Y' -Or $FirstRun -eq 'y') {
        Write-Output "`n [ START ] Instaling Common Requirements"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        Set-ExecutionPolicy Bypass -Scope Process -Force; Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
        RefreshEnv
        cinst -y boxstarter
        
        $StopWatch.Stop()
        $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
        Write-Output " [ DONE ] Instaling Common Requirements ... $StopWatchElapsed seconds`n"
        Write-Output "`n [ START ] Windows Update"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        Enable-UAC
        Enable-MicrosoftUpdate
        Update-Help
        Install-WindowsUpdate -acceptEula
        Disable-WindowsUpdate
        Disable-UAC
        $StopWatch.Stop()
        $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
        Write-Output " [ DONE ] Windows Update ... $StopWatchElapsed seconds`n"
        $Privacy = Read-Host -Prompt "`n Do you care about privacy? (Y/n)"
        if ([string]::IsNullOrWhiteSpace($Privacy) -Or $Privacy -eq 'Y' -Or $Privacy -eq 'y') {
            Write-Output "`n [ START ] Protecting Privacy"
            $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
            #Disables Windows Feedback Experience
            Write-Output " [ DOING ] Disabling Windows Feedback Experience program"
            $Advertising = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            If (Test-Path $Advertising) {
                Set-ItemProperty $Advertising Enabled -Value 0 
            }
            #Stops Cortana from being used as part of your Windows Search Function
            Write-Output " [ DOING ] Stopping Cortana from being used as part of your Windows Search Function"
            $Search = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            If (Test-Path $Search) {
                Set-ItemProperty $Search AllowCortana -Value 0 
            }
            #Disables Web Search in Start Menu
            Write-Output " [ DOING ] Disabling Bing Search in Start Menu"
            $WebSearch = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            Set-ItemProperty "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" BingSearchEnabled -Value 0 
            If (!(Test-Path $WebSearch)) {
                New-Item $WebSearch
            }
            New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name DisableWebSearch -Type DWORD -Value 1
            Set-ItemProperty $WebSearch DisableWebSearch -Value 1
            #Stops the Windows Feedback Experience from sending anonymous data
            Write-Output " [ DOING ] Stopping the Windows Feedback Experience program"
            $Period = "HKCU:\Software\Microsoft\Siuf\Rules"
            If (!(Test-Path $Period)) { 
                New-Item $Period
            }
            Set-ItemProperty $Period PeriodInNanoSeconds -Value 0 
            #Prevents bloatware applications from returning and removes Start Menu suggestions               
            Write-Output " [ DOING ] Adding Registry key to prevent bloatware apps from returning"
            $registryPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            $registryOEM = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            If (!(Test-Path $registryPath)) { 
                New-Item $registryPath
            }
            Set-ItemProperty $registryPath DisableWindowsConsumerFeatures -Value 1 
            If (!(Test-Path $registryOEM)) {
                New-Item $registryOEM
            }
            Set-ItemProperty $registryOEM  ContentDeliveryAllowed -Value 0 
            Set-ItemProperty $registryOEM  OemPreInstalledAppsEnabled -Value 0 
            Set-ItemProperty $registryOEM  PreInstalledAppsEnabled -Value 0 
            Set-ItemProperty $registryOEM  PreInstalledAppsEverEnabled -Value 0 
            Set-ItemProperty $registryOEM  SilentInstalledAppsEnabled -Value 0 
            Set-ItemProperty $registryOEM  SystemPaneSuggestionsEnabled -Value 0          
            #Preping mixed Reality Portal for removal    
            Write-Output " [ DOING ] Setting Mixed Reality Portal value to 0 so that you can uninstall it in Settings"
            $Holo = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Holographic"    
            If (Test-Path $Holo) {
                Set-ItemProperty $Holo  FirstRunSucceeded -Value 0 
            }
            #Disables Wi-fi Sense
            Write-Output " [ DOING ] Disabling Wi-Fi Sense"
            $WifiSense1 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting"
            $WifiSense2 = "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots"
            $WifiSense3 = "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config"
            If (!(Test-Path $WifiSense1)) {
                New-Item $WifiSense1
            }
            Set-ItemProperty $WifiSense1  Value -Value 0 
            If (!(Test-Path $WifiSense2)) {
                New-Item $WifiSense2
            }
            Set-ItemProperty $WifiSense2  Value -Value 0 
            Set-ItemProperty $WifiSense3  AutoConnectAllowedOEM -Value 0 
            #Disables live tiles
            Write-Output " [ DOING ] Disabling live tiles"
            $Live = "HKCU:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\PushNotifications"    
            If (!(Test-Path $Live)) {      
                New-Item $Live
            }
            Set-ItemProperty $Live  NoTileApplicationNotification -Value 1 
            #Turns off Data Collection via the AllowTelemtry key by changing it to 0
            Write-Output " [ DOING ] Turning off Data Collection"
            $DataCollection1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection"
            $DataCollection2 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            $DataCollection3 = "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Policies\DataCollection"    
            If (Test-Path $DataCollection1) {
                Set-ItemProperty $DataCollection1  AllowTelemetry -Value 0 
            }
            If (Test-Path $DataCollection2) {
                Set-ItemProperty $DataCollection2  AllowTelemetry -Value 0 
            }
            If (Test-Path $DataCollection3) {
                Set-ItemProperty $DataCollection3  AllowTelemetry -Value 0 
            }
            #Disabling Location Tracking
            Write-Output " [ DOING ] Disabling Location Tracking"
            $SensorState = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Sensor\Overrides\{BFA794E4-F964-4FDB-90F6-51056BFE4B44}"
            $LocationConfig = "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration"
            If (!(Test-Path $SensorState)) {
                New-Item $SensorState
            }
            Set-ItemProperty $SensorState SensorPermissionState -Value 0 
            If (!(Test-Path $LocationConfig)) {
                New-Item $LocationConfig
            }
            Set-ItemProperty $LocationConfig Status -Value 0 
            #Disables People icon on Taskbar
            Write-Output " [ DOING ] Disabling People icon on Taskbar"
            $People = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\People"    
            If (!(Test-Path $People)) {
                New-Item $People
            }
            Set-ItemProperty $People  PeopleBand -Value 0 
            #Disables scheduled tasks that are considered unnecessary 
            Write-Output " [ DOING ] Disabling scheduled tasks"
            Get-ScheduledTask  XblGameSaveTaskLogon | Disable-ScheduledTask
            Get-ScheduledTask  XblGameSaveTask | Disable-ScheduledTask
            Get-ScheduledTask  Consolidator | Disable-ScheduledTask
            Get-ScheduledTask  UsbCeip | Disable-ScheduledTask
            Get-ScheduledTask  DmClient | Disable-ScheduledTask
            Get-ScheduledTask  DmClientOnScenarioDownload | Disable-ScheduledTask
            Write-Output " [ DOING ] Stopping and disabling WAP Push Service"
            #Stop and disable WAP Push Service
            Stop-Service "dmwappushservice"
            Set-Service "dmwappushservice" -StartupType Disabled
            Write-Output " [ DOING ] Stopping and disabling Diagnostics Tracking Service"
            #Disabling the Diagnostics Tracking Service
            Stop-Service "DiagTrack"
            Set-Service "DiagTrack" -StartupType Disabled
            $StopWatch.Stop()
            $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
            Write-Output " [ DONE ] Protecting Privacy ... $StopWatchElapsed seconds`n"
        }
        $WindowsConfig = Read-Host -Prompt "`n Do wish configure Windows? (Y/n)"
        if ([string]::IsNullOrWhiteSpace($WindowsConfig) -Or $WindowsConfig -eq 'Y' -Or $WindowsConfig -eq 'y') {
            Write-Output "`n [ DOING ] Setting network category to private"
            Set-NetConnectionProfile -NetworkCategory Private
            Write-Output "`n [ DOING ] Setting dark theme as default"
            Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize -Name AppsUseLightTheme -Value 0
            Write-Output "`n [ DOING ] Show hidden files, Show protected OS files, Show file extensions"
            Set-WindowsExplorerOptions -EnableShowHiddenFilesFoldersDrives -EnableShowProtectedOSFiles -EnableShowFileExtensions
            Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced HideFileExt "0"
            #--- File Explorer Settings ---
            Write-Output "`n [ DOING ] Adds things back in your left pane like recycle bin"
            Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneExpandToCurrentFolder -Value 1
            Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name NavPaneShowAllFolders -Value 1
            Write-Output "`n [ DOING ] Opens PC to This PC, not quick access"
            Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name LaunchTo -Value 1
            Write-Output "`n [ DOING ] Taskbar where window is open for multi-monitor"
            Set-ItemProperty -Path HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced -Name MMTaskbarMode -Value 2
            Write-Output "`n [ DOING ] Disable Quick Access: Recent Files"
            Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowRecent -Type DWord -Value 0
            Write-Output "`n [ DOING ] Disable Quick Access: Frequent Folders"
            Set-ItemProperty -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer -Name ShowFrequent -Type DWord -Value 0
            Stop-Process -processName: Explorer -force # This will restart the Explorer service to make this work.
        }
        Write-Output "`n [ START ] Unistall Windows10 Unnecessary and Blotware Apps"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        $AppXApps = @(
            "*Microsoft.BingNews*"
            "*Microsoft.GetHelp*"
            "*Microsoft.Getstarted*"
            "*Microsoft.Messaging*"
            "*Microsoft.Microsoft3DViewer*"
            "*Microsoft.MicrosoftOfficeHub*"
            "*Microsoft.MicrosoftSolitaireCollection*"
            "*Microsoft.NetworkSpeedTest*"
            "*Microsoft.Office.Sway*"
            "*Microsoft.OneConnect*"
            "*Microsoft.People*"
            "*Microsoft.Print3D*"
            "*Microsoft.SkypeApp*"
            "*Microsoft.CommsPhone*"
            "*Microsoft.WindowsAlarms*"
            "*Microsoft.WindowsCamera*"
            "*microsoft.windowscommunicationsapps*"
            "*Microsoft.WindowsFeedbackHub*"
            "*Microsoft.WindowsMaps*"
            "*Microsoft.WindowsSoundRecorder*"
            "*Microsoft.Xbox.TCUI*"
            "*Microsoft.XboxApp*"
            "*Microsoft.XboxGameOverlay*"
            "*Microsoft.XboxIdentityProvider*"
            "*Microsoft.XboxSpeechToTextOverlay*"
            "*Microsoft.ZuneMusic*"
            "*Microsoft.People*"
            "*Microsoft.ZuneVideo*"
            #Sponsored Windows 10 AppX Apps
            #Add sponsored/featured apps to remove in the "*AppName*" format
            "*EclipseManager*"
            "*Autodesk*"
            "*BubbleWitch*"
            "*MarchofEmpires*"
            "*McAfee*"
            "*Minecraft*"
            "*Netflix*"
            "*ActiproSoftwareLLC*"
            "*AdobeSystemsIncorporated.AdobePhotoshopExpress*"
            "*Duolingo-LearnLanguagesforFree*"
            "*PandoraMediaInc*"
            "*CandyCrush*"
            "*Wunderlist*"
            "*Flipboard*"
            "*Twitter*"
            "*Facebook*"
            "*Spotify*"
            #Optional: Typically not removed but you can if you need to for some reason
            #"*Microsoft.Advertising.Xaml_10.1712.5.0_x64__8wekyb3d8bbwe*"
            #"*Microsoft.Advertising.Xaml_10.1712.5.0_x86__8wekyb3d8bbwe*"
            #"*Microsoft.BingWeather*"
            #"*Microsoft.MSPaint*"
            #"*Microsoft.MicrosoftStickyNotes*"
            #"*Microsoft.Windows.Photos*"
            #"*Microsoft.WindowsCalculator*"
            #"*Microsoft.WindowsStore*"
        )
        foreach ($App in $AppXApps) {
            Write-Output " [ DOING ] Removing $App from registry"
            Get-AppxPackage -Name $App | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage -Name $App -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online | Where-Object DisplayName -like $App | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
        }
        [regex]$WhitelistedApps = 'Microsoft.Paint3D|Microsoft.WindowsCalculator|Microsoft.WindowsStore|Microsoft.Windows.Photos|CanonicalGroupLimited.UbuntuonWindows|Microsoft.XboxGameCallableUI|Microsoft.XboxGamingOverlay|Microsoft.Xbox.TCUI|Microsoft.XboxGamingOverlay|Microsoft.XboxIdentityProvider|Microsoft.MicrosoftStickyNotes|Microsoft.MSPaint*'
        Get-AppxPackage -AllUsers | Where-Object { $_.Name -NotMatch $WhitelistedApps } | Remove-AppxPackage
        Get-AppxPackage | Where-Object { $_.Name -NotMatch $WhitelistedApps } | Remove-AppxPackage
        Get-AppxProvisionedPackage -Online | Where-Object { $_.PackageName -NotMatch $WhitelistedApps } | Remove-AppxProvisionedPackage -Online
        $StopWatch.Stop()
        $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
        Write-Output " [ DONE ] Unistall Windows10 Unnecessary and Blotware Apps ... $StopWatchElapsed seconds`n"
        Write-Output "`n [ START ] Remove Unnecessary Windows Registries"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        $Keys = @(
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.BackgroundTasks\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            #Windows File
            "HKCR:\Extensions\ContractId\Windows.File\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            #Registry keys to delete if they aren't uninstalled by RemoveAppXPackage/RemoveAppXProvisionedPackage
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\46928bounde.EclipseManager_2.2.4.51_neutral__a5h4egax66k6y"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Launch\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            #Scheduled Tasks to delete
            "HKCR:\Extensions\ContractId\Windows.PreInstalledConfigTask\PackageId\Microsoft.MicrosoftOfficeHub_17.7909.7600.0_x64__8wekyb3d8bbwe"
            #Windows Protocol Keys
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.PPIProjection_10.0.15063.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.15063.0.0_neutral_neutral_cw5n1h2txyewy"
            "HKCR:\Extensions\ContractId\Windows.Protocol\PackageId\Microsoft.XboxGameCallableUI_1000.16299.15.0_neutral_neutral_cw5n1h2txyewy"
            #Windows Share Target
            "HKCR:\Extensions\ContractId\Windows.ShareTarget\PackageId\ActiproSoftwareLLC.562882FEEB491_2.6.18.18_neutral__24pqs290vpjk0"
        )
        ForEach ($Key in $Keys) {
            Write-Output " [ DOING ] Removing $Key from registry"
            Remove-Item $Key -Recurse
        }
        $StopWatch.Stop()
        $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
        Write-Output " [ DONE ] Remove Unnecessary Windows Registries ... $StopWatchElapsed seconds`n"
        if ($env:computername -ne $ComputerName) {
            Rename-Computer -NewName $ComputerName
        }
    }
    else {
        $PurgeMode = Read-Host -Prompt "`n Enable Purge Mode (y/N)"
        if ($PurgeMode -eq 'Y' -Or $PurgeMode -eq 'y') {
        }
    }
    $AllPrograms = Get-Content 'bootstrap\w10-settings.json' | Out-String | ConvertFrom-Json
    if ($InstalationType -eq '1') {
        Write-Output "`n [ START ] Software Instalation List"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        $DefaultProgram = Read-Host -Prompt "`n Use default program instalation (y/N)"
        ForEach ($row in $AllPrograms.programs) {
            if ($DefaultProgram -eq 'Y' -Or $DefaultProgram -eq 'y') {
                $row.installation = $row.default
            }
        }
        $AllPrograms | ConvertTo-Json -depth 100 | Out-File -Encoding UTF8 'bootstrap\w10-settings.json'
        ForEach ($row in $AllPrograms.programs) {
            $ProgramName = $row.name
            $ProgramInstallation = $row.installation
            Write-Output "$ProgramName : $ProgramInstallation"
        }
        Start-Sleep -s 3
        $StopWatch.Stop()
        $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
        Write-Output " [ DONE ] Software Instalation List ... $StopWatchElapsed seconds`n"
    }
    elseif ($InstalationType -eq '2') {
        ForEach ($row in $AllPrograms.programs) {
            $ProgramName = $row.name
            $ProgramDefault = $row.default
            if ($row.default -eq $true) {
                $DefaultOption = '(Y/n)'
            }
            else {
                $DefaultOption = '(y/N)'
            }
            $ProgramOption = Read-Host -Prompt "`n Install $ProgramName ? $DefaultOption"
            if ($ProgramOption -eq 'Y' -Or $ProgramOption -eq 'y') {
                $ProgramInstallation = $true
            }
            elseif ([string]::IsNullOrWhiteSpace($ProgramOption)) {
                $ProgramInstallation = $ProgramDefault
            }
            else {
                $ProgramInstallation = $false
            }
            $row.installation = $ProgramInstallation
        }
        $AllPrograms | ConvertTo-Json -depth 100 | Out-File -Encoding UTF8 'bootstrap\w10-settings.json'
    }
    else {
        
    }
    Write-Output "`n [ DOING ] Enable developer mode on the system"
    Set-ItemProperty -Path HKLM:\Software\Microsoft\Windows\CurrentVersion\AppModelUnlock -Name AllowDevelopmentWithoutDevLicense -Value 1
    Disable-UAC
    $Programs = @(
        #Fonts
        "hackfont"
        "firacode"
        "inconsolata"
        "dejavufonts"
        "robotofonts"
        #Default Install
        "k-litecodecpackfull"
        "ffmpeg"
        "jre8"
        "7zip"
        "googlechrome"
        "autohotkey"
        "sysinternals"
        # Dev Tools Must Have
        "git.install"
        "lepton"
        "powershell"
        "virtualbox"
        "vagrant"
        "putty"
    )
    ForEach ($Program in $Programs) {
        Write-Output "`n [ START ] $Program"
        $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
        cinst -y $Program
        $StopWatch.Stop()
        $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
        Write-Output " [ DONE ] $Program ... $StopWatchElapsed seconds`n"
    }
    $AllPrograms = Get-Content 'bootstrap\w10-settings.json' | Out-String | ConvertFrom-Json
    ForEach ($row in $AllPrograms.programs) {
        $ProgramName = $row.name
        $ProgramInstallation = $row.installation
        if ($ProgramInstallation -eq $true) {
            Write-Output "`n [ START ] $ProgramName"
            $StopWatch = [System.Diagnostics.Stopwatch]::StartNew()
            $ProgramSlug = $row.program
            Invoke-Expression ".\programs\$ProgramSlug.ps1"
            $StopWatch.Stop()
            $StopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
            Write-Output " [ DONE ] $ProgramName ... $StopWatchElapsed  seconds`n"
        }
    }
    Enable-UAC
    RefreshEnv
    Start-Process -FilePath 'autoruns' -Wait
    $OzoneInstall = Read-Host -Prompt "`n Do you wish to install Ozone Exon V30 Mice Driver? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($OzoneInstall) -Or $OzoneInstall -eq 'Y' -Or $OzoneInstall -eq 'y') {
        Start-Process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList 'https://www.ozonegaming.com/product/exon-v30'
    }
    $OfficeInstall = Read-Host -Prompt "`n Do you wish to install Office? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($OfficeInstall) -Or $OfficeInstall -eq 'Y' -Or $OfficeInstall -eq 'y') {
        Start-Process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList 'https://old.reddit.com/r/sjain_guides/comments/9m4m0k/microsoft_office_201319_simple_method_to_download'
    }
    $AdobeInstall = Read-Host -Prompt "`n Do you wish to install Adobe Products? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($AdobeInstall) -Or $AdobeInstall -eq 'Y' -Or $AdobeInstall -eq 'y') {
        Start-Process -FilePath 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe' -ArgumentList 'https://old.reddit.com/r/sjain_guides/wiki/downloads'
    }
    function Set-DefaultBrowser {
        param($defaultBrowser)
        $regKey = "HKCU:\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\{0}\UserChoice"
        $regKeyHttp = $regKey -f 'http'
        $regKeyHttps = $regKey -f 'https'
        switch -Regex ($defaultBrowser.ToLower()) {
            # Internet Explorer
            'ie|internet|explorer' {
                Set-ItemProperty $regKeyHttp  -name ProgId IE.HTTP
                Set-ItemProperty $regKeyHttps -name ProgId IE.HTTPS
                break
            }
            # Firefox
            'ff|firefox' {
                Set-ItemProperty $regKeyHttp  -name ProgId FirefoxURL
                Set-ItemProperty $regKeyHttps -name ProgId FirefoxURL
                break
            }
            # Google Chrome
            'cr|google|chrome' {
                Set-ItemProperty $regKeyHttp  -name ProgId ChromeHTML
                Set-ItemProperty $regKeyHttps -name ProgId ChromeHTML
                break
            }
            # Safari
            'sa*|apple' {
                Set-ItemProperty $regKeyHttp  -name ProgId SafariURL
                Set-ItemProperty $regKeyHttps -name ProgId SafariURL
                break
            }
            # Opera
            'op*' {
                Set-ItemProperty $regKeyHttp  -name ProgId Opera.Protocol
                Set-ItemProperty $regKeyHttps -name ProgId Opera.Protocol
                break
            }
        }
    }
    Set-DefaultBrowser chrome
    $GlobalStopWatch.Stop()
    $GlobalStopWatchElapsed = $StopWatch.Elapsed.TotalSeconds
    Write-Output "`n Total Execution Time ... $GlobalStopWatchElapsed seconds`n" 
}
else {
    Write-Output "`n [ ERROR ] You must execute this script with administrator privileges`n"
}
