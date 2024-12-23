# Elevate to admin privileges if not already running as admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

# Function to attempt uninstallation
function Attempt-Uninstall {
    param (
        [string]$DisplayName,
        [string]$UninstallString
    )
    Write-Host "Attempting to uninstall $DisplayName"
    if ($UninstallString -like "MsiExec.exe*") {
        $args = ($UninstallString -split ' ', 2)[1] + ' /qn'
        Start-Process "msiexec.exe" -ArgumentList $args -Wait
    } else {
        $process = Start-Process $UninstallString -Wait -PassThru
        $exitCode = $process.ExitCode
        Write-Host "Uninstall process exited with code: $exitCode"
    }
}

# Stop all Grafana-related services
Get-Service | Where-Object {$_.Name -like "*Grafana*"} | Stop-Service -Force -ErrorAction SilentlyContinue

# Attempt to uninstall using registered uninstallers
Get-ChildItem -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall, HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall |
    Get-ItemProperty |
    Where-Object {$_.DisplayName -like "*Grafana*" -or $_.DisplayName -like "*Alloy*"} |
    ForEach-Object {
        Attempt-Uninstall -DisplayName $_.DisplayName -UninstallString $_.UninstallString
    }

# Force remove Grafana directories
$directories = @(
    "C:\Program Files\Grafana",
    "C:\Program Files (x86)\Grafana",
    "C:\ProgramData\Grafana"
)

foreach ($dir in $directories) {
    if (Test-Path $dir) {
        Write-Host "Removing $dir"
        Remove-Item -Path $dir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Clean up registry
$registryPaths = @(
    "HKLM:\SOFTWARE\Grafana",
    "HKLM:\SOFTWARE\WOW6432Node\Grafana"
)

foreach ($path in $registryPaths) {
    if (Test-Path $path) {
        Write-Host "Removing registry key $path"
        Remove-Item -Path $path -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove Grafana services
Get-WmiObject Win32_Service | Where-Object {$_.Name -like "*Grafana*"} | ForEach-Object {
    Write-Host "Removing service $($_.Name)"
    $_.Delete()
}

Write-Host "Uninstallation process completed. Please reboot your system to ensure all changes take effect."