# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Enable IIS and required features
Write-Output "Enabling IIS and required features..."
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerRole -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebServerManagementTools -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CommonHttpFeatures -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpErrors -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticContent -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpRedirect -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpLogging -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-LoggingLibraries -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestMonitor -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-HttpTracing -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-StaticCompression -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-DynamicCompression -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Security -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-Filtering -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-BasicAuthentication -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WindowsAuthentication -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-RequestFiltering -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ApplicationDevelopment -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-NetFxExtensibility45 -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ASPNET45 -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-CGI -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIFilter -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ISAPIExtensions -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-WebSockets -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementService -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ManagementConsole -All -NoRestart
Enable-WindowsOptionalFeature -Online -FeatureName IIS-ScriptingTools -All -NoRestart

# Restart the computer to complete installation
Write-Output "Restarting the computer to complete installation..."
Restart-Computer
