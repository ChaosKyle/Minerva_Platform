# Variables
$sourceDir = "C:\Users\Kylel\Lobby\minerva"
$destDir = "C:\Users\Kylel\Lobby\minerva_git"

# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Sync source directory to destination directory
Write-Output "Copying $sourceDir to $destDir..."
Robocopy $sourceDir $destDir /MIR /XF .git

# Navigate to the destination directory
Set-Location $destDir

# Add all changes
git add .

# Commit changes with a message
$commitMessage = "Deploying updates from minerva on $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
git commit -m $commitMessage

# Push changes to the origin repository
git push origin main

Write-Output "Deployment and backup completed successfully."
