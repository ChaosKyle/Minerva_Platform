# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Variables
$siteName = "Minerva"
$sitePath = "C:\inetpub\wwwroot\Minerva"
$cssPath = "$sitePath\css"
$port = 8080

# Create directories for the site if they don't exist
if (-Not (Test-Path $sitePath)) {
    New-Item -Path $sitePath -ItemType Directory -Force
}

if (-Not (Test-Path $cssPath)) {
    New-Item -Path $cssPath -ItemType Directory -Force
}

# Create a style.css file for the site
$cssContent = @"
body {
    background-color: #121212;
    color: #ffffff;
    font-family: Arial, sans-serif;
    display: flex;
    justify-content: center;
    align-items: center;
    height: 100vh;
    margin: 0;
}

.container {
    display: flex;
    flex-wrap: wrap;
    justify-content: center;
}

.box {
    width: 200px;
    height: 200px;
    margin: 10px;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #1e1e1e;
    border: 1px solid #333;
    border-radius: 10px;
    text-align: center;
    font-size: 20px;
    transition: transform 0.2s, box-shadow 0.2s;
}

.box a {
    text-decoration: none;
    color: inherit;
}

.box:hover {
    transform: scale(1.1);
    box-shadow: 0 0 15px rgba(255, 255, 255, 0.2);
}
"@

Set-Content -Path "$cssPath\style.css" -Value $cssContent

# Create an index.html file for the site
$htmlContent = @"
<!DOCTYPE html>
<html lang='en'>
<head>
    <meta charset='UTF-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1.0'>
    <title>Minerva Platform</title>
    <link rel='stylesheet' href='css/style.css'>
</head>
<body>
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
