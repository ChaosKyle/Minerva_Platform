# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Install IIS and required features
Write-Output "Installing IIS and required features..."
Install-WindowsFeature -name Web-Server -IncludeManagementTools

# Enable necessary IIS features
$features = @(
    "Web-Common-Http",
    "Web-Default-Doc",
    "Web-Dir-Browsing",
    "Web-Http-Errors",
    "Web-Static-Content",
    "Web-Http-Redirect",
    "Web-Health",
    "Web-Http-Logging",
    "Web-Log-Libraries",
    "Web-Request-Monitor",
    "Web-Http-Tracing",
    "Web-Performance",
    "Web-Stat-Compression",
    "Web-Dyn-Compression",
    "Web-Security",
    "Web-Filtering",
    "Web-Basic-Auth",
    "Web-Windows-Auth",
    "Web-Url-Auth",
    "Web-App-Dev",
    "Web-Net-Ext",
    "Web-Net-Ext45",
    "Web-Asp-Net",
    "Web-Asp-Net45",
    "Web-CGI",
    "Web-ISAPI-Ext",
    "Web-ISAPI-Filter",
    "Web-Includes",
    "Web-WebSockets",
    "Web-Mgmt-Tools",
    "Web-Mgmt-Console",
    "Web-Mgmt-Service",
    "Web-Scripting-Tools"
)

foreach ($feature in $features) {
    Install-WindowsFeature -Name $feature
}

# Start the IIS service
Write-Output "Starting IIS service..."
Start-Service W3SVC

# Verify installation
if (Get-Service W3SVC -ErrorAction SilentlyContinue) {
    Write-Output "IIS installation successful!"
} else {
    Write-Output "IIS installation failed."
}

# Create a new IIS website
$siteName = "FamilyPlatform"
$sitePath = "C:\inetpub\wwwroot\FamilyPlatform"
$port = 8080

# Create a directory for the new site if it doesn't exist
if (-Not (Test-Path $sitePath)) {
    New-Item -Path $sitePath -ItemType Directory -Force
}

# Create an index.html file for the site
$htmlContent = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Family Platform</title>
    <style>
        .container {
            display: flex;
            flex-wrap: wrap;
        }
        .box {
            width: 200px;
            height: 200px;
            margin: 10px;
            display: flex;
            align-items: center;
            justify-content: center;
            background-color: #f0f0f0;
            border: 1px solid #ccc;
            border-radius: 10px;
            text-align: center;
            font-size: 20px;
        }
        .box a {
            text-decoration: none;
            color: inherit;
        }
    </style>
</head>
<body>
    <h1>Family Platform</h1>
    <div class="container">
        <div class="box"><a href="http://localhost:8081">Chore Tracking</a></div>
        <div class="box"><a href="http://localhost:8082">Meal Planning</a></div>
        <div class="box"><a href="http://localhost:8083">Fitness Planning</a></div>
        <div class="box"><a href="http://localhost:8084">Trip Planning</a></div>
        <div class="box"><a href="http://localhost:8085">Google Calendar</a></div>
    </div>
</body>
</html>
"@

Set-Content -Path "$sitePath\index.html" -Value $htmlContent

# Import WebAdministration module to manage IIS
Import-Module WebAdministration

# Check if the site already exists
if (Get-Website -Name $siteName -ErrorAction SilentlyContinue) {
    Write-Output "A site with the name $siteName already exists. Removing the existing site."
    Remove-Website -Name $siteName
}

# Create the new website
Write-Output "Creating a new IIS website: $siteName"
New-Website -Name $siteName -Port $port -PhysicalPath $sitePath -ApplicationPool "DefaultAppPool"

Write-Output "IIS website $siteName created successfully and is accessible at http://localhost:$port"

Write-Output "Setup complete. You can now access your Family Platform site and start adding your Dockerized apps."
