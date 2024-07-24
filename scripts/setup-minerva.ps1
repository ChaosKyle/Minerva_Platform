# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Variables
$siteName = "Minerva"
$sitePath = "C:\inetpub\wwwroot\Minerva"
$port = 8080

# Create a directory for the new site if it doesn't exist
if (-Not (Test-Path $sitePath)) {
    New-Item -Path $sitePath -ItemType Directory -Force
}

# Create an index.html file for the site
$htmlContent = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Minerva Platform</title>
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
    <h1>Minerva Platform</h1>
    <div class='container'>
        <div class='box'><a href='http://localhost:8081'>Chore Tracking</a></div>
        <div class='box'><a href='http://localhost:8082'>Meal Planning</a></div>
        <div class='box'><a href='http://localhost:8083'>Fitness Planning</a></div>
        <div class='box'><a href='http://localhost:8084'>Trip Planning</a></div>
        <div class='box'><a href='http://localhost:8085'>Google Calendar</a></div>
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

Write-Output "Setup complete. You can now access your Minerva Platform site and start adding your Dockerized apps."
