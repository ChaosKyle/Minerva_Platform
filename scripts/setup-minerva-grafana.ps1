# Check if running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Warning "You need to run this script as an Administrator!"
    exit
}

# Variables
$siteName = "Minerva"
$sitePath = "C:\inetpub\wwwroot\Minerva"
$cssPath = "$sitePath\css"
$imagesPath = "$sitePath\images"
$port = 8080

# Create directories for the site if they don't exist
if (-Not (Test-Path $sitePath)) {
    New-Item -Path $sitePath -ItemType Directory -Force
}

if (-Not (Test-Path $cssPath)) {
    New-Item -Path $cssPath -ItemType Directory -Force
}

if (-Not (Test-Path $imagesPath)) {
    New-Item -Path $imagesPath -ItemType Directory -Force
}

# Create a style.css file for the site
$cssContent = @"
body {
    background-color: #121212;
    color: #ffffff;
    font-family: Arial, sans-serif;
    display: flex;
    flex-direction: column;
    align-items: center;
    min-height: 100vh;
    margin: 0;
    padding: 20px;
    box-sizing: border-box;
}

h1 {
    color: limegreen;
    font-size: 48px;
    margin-bottom: 20px;
}

.image-container {
    position: relative;
    margin: 20px;
}

.image-container img {
    width: 300px;
    border-radius: 15px;
    box-shadow: 0 0 15px rgba(0, 255, 0, 0.5);
}

.container {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 20px;
    max-width: 1200px;
    width: 100%;
    margin: 20px 0;
}

.box {
    height: 200px;
    display: flex;
    align-items: center;
    justify-content: center;
    background-color: #333;
    border: 1px solid #444;
    border-radius: 10px;
    text-align: center;
    font-size: 20px;
    transition: transform 0.2s, box-shadow 0.2s;
    color: white;
}

.box a {
    text-decoration: none;
    color: inherit;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: center;
}

.box:hover {
    transform: scale(1.05);
    box-shadow: 0 0 15px rgba(255, 255, 255, 0.2);
}

.video-container {
    margin: 20px;
}

.video-container iframe {
    width: 560px;
    height: 315px;
    border: none;
    border-radius: 15px;
    box-shadow: 0 0 15px rgba(0, 255, 0, 0.5);
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
    <h1>Minerva</h1>
    <div class='image-container'>
        <img src='images/placeholder.png' alt='Cool Image'>
    </div>
    <div class='container'>
        <div class='box'><a href='http://localhost:8081'>Chore Tracking</a></div>
        <div class='box'><a href='http://localhost:8082'>Meal Planning</a></div>
        <div class='box'><a href='http://localhost:8083'>Fitness Planning</a></div>
        <div class='box'><a href='http://localhost:8084'>Trip Planning</a></div>
        <div class='box'><a href='http://localhost:8085'>Google Calendar</a></div>
        <div class='box'><a href='http://localhost:3000'>Grafana</a></div>
    </div>
</body>
</html>
"@

Set-Content -Path "$sitePath\index.html" -Value $htmlContent

# Add a placeholder image (assuming you have a placeholder image saved locally as placeholder.png)
# For this script to work, make sure you have a placeholder.png image in the same directory as this script.
Copy-Item -Path ".\placeholder.png" -Destination "$imagesPath\placeholder.png" -Force

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