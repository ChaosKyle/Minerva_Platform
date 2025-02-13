param (
    [string]$SiteName = "Minerva",
    [string]$SitePath = "C:\inetpub\wwwroot\Minerva",
    [string]$RootPath = "C:\Users\kylel\Lobby\Minerva",
    [int]$Port = 8500
)

# --- 1. Require Admin Privileges ---
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "ERROR: Please run this script in an elevated PowerShell prompt (Administrator)."
    exit 1
}

# --- 2. Ensure the WebAdministration module is available ---
if (-not (Get-Module -ListAvailable -Name WebAdministration)) {
    Write-Host "ERROR: WebAdministration module is not available. Install IIS and ensure the module is loaded."
    exit 1
}
Import-Module WebAdministration -ErrorAction Stop

Write-Host "----- Starting deployment for '$SiteName' on port $Port -----"

# --- 3. Clean up existing resources ---
Write-Host "Cleaning up existing resources..."
# Stop and remove containers
docker stop grafana n8n 2>$null
docker rm grafana n8n 2>$null

# Remove existing website
if (Get-Website -Name $SiteName) {
    Remove-Website -Name $SiteName
}

# --- 4. Create root directory structure ---
Write-Host "Creating root directory structure..."
$rootDirs = @(
    $RootPath,
    "$RootPath\apps",
    "$RootPath\css",
    "$RootPath\images",
    "$RootPath\scripts"
)

foreach ($dir in $rootDirs) {
    if (-not (Test-Path $dir)) {
        Write-Host "Creating directory: $dir"
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    } else {
        Write-Host "Directory already exists: $dir"
    }
}

# --- 5. Create basic HTML ---
$indexHtml = @'
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minerva Platform</title>
    <link rel="stylesheet" href="css/styles.css">
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">Minerva</h1>
            <img src="images/placeholder.png" alt="Minerva" class="minerva-image">
        </div>
        <div class="grid">
            <a href="http://localhost:3000" class="card" target="_blank" rel="noopener noreferrer">
                <span>Grafana</span>
                <div class="shine"></div>
            </a>
            <a href="http://localhost:5678" class="card" target="_blank" rel="noopener noreferrer">
                <span>n8n</span>
                <div class="shine"></div>
            </a>
        </div>
    </div>
</body>
</html>
'@

# --- 6. Create enhanced CSS ---
$cssContent = @'
body {
    font-family: Arial, sans-serif;
    margin: 0;
    padding: 20px;
    background-color: #f0f2f5;
}

.container {
    max-width: 1200px;
    margin: 0 auto;
}

.header {
    text-align: center;
    margin-bottom: 40px;
}

.title {
    font-size: 4em;
    font-weight: 700;
    color: #2c3e50;
    text-transform: uppercase;
    letter-spacing: 4px;
    margin-bottom: 30px;
    position: relative;
    text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
    background: linear-gradient(45deg, #2c3e50, #3498db, #2c3e50);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
    animation: gradient 8s ease infinite;
}

@keyframes gradient {
    0% {
        background-position: 0% 50%;
    }
    50% {
        background-position: 100% 50%;
    }
    100% {
        background-position: 0% 50%;
    }
}

.title::after {
    content: '';
    position: absolute;
    bottom: -10px;
    left: 50%;
    transform: translateX(-50%);
    width: 60%;
    height: 2px;
    background: linear-gradient(90deg, 
        rgba(44,62,80,0), 
        rgba(44,62,80,0.8), 
        rgba(44,62,80,0));
}

.minerva-image {
    max-width: 300px;
    border-radius: 10px;
    box-shadow: 0 4px 8px rgba(0,0,0,0.2);
}

.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
    gap: 30px;
    padding: 20px;
    max-width: 800px;
    margin: 0 auto;
}

.card {
    background: white;
    padding: 30px;
    border-radius: 15px;
    text-align: center;
    text-decoration: none;
    color: #333;
    transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
    box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    position: relative;
    overflow: hidden;
    border: 2px solid transparent;
    display: flex;
    align-items: center;
    justify-content: center;
    min-height: 100px;
}

.card:hover {
    transform: translateY(-5px) scale(1.02);
    box-shadow: 0 8px 15px rgba(0,0,0,0.2);
    border-color: rgba(0,0,0,0.1);
    background: linear-gradient(145deg, #ffffff, #f0f0f0);
}

span {
    font-weight: 600;
    font-size: 24px;
    color: #2c3e50;
    transition: color 0.3s ease;
    z-index: 1;
}

.card:hover span {
    color: #000;
}

.shine {
    position: absolute;
    top: 0;
    left: -100%;
    width: 50%;
    height: 100%;
    background: linear-gradient(
        120deg,
        transparent,
        rgba(255,255,255,0.6),
        transparent
    );
    transition: 0.5s;
}

.card:hover .shine {
    left: 100%;
}

@media (max-width: 600px) {
    .grid {
        grid-template-columns: 1fr;
        padding: 10px;
    }
    
    .card {
        padding: 20px;
    }

    .minerva-image {
        max-width: 90%;
    }

    .title {
        font-size: 3em;
    }
}
'@

# --- 7. Write files to root directory ---
Write-Host "Writing application files to root directory..."
Set-Content -Path (Join-Path $RootPath "index.html") -Value $indexHtml
Set-Content -Path (Join-Path $RootPath "css\styles.css") -Value $cssContent

# --- 8. Set up IIS site ---
Write-Host "Setting up IIS site..."
if (-not (Test-Path $SitePath)) {
    New-Item -ItemType Directory -Path $SitePath -Force | Out-Null
}

# Copy files from root to IIS path
Write-Host "Copying files to IIS directory..."
Copy-Item -Path "$RootPath\*" -Destination $SitePath -Recurse -Force

# --- 9. Create and configure IIS website ---
Write-Host "Creating IIS website..."
New-Website -Name $SiteName -PhysicalPath $SitePath -Port $Port -Force

# Enable Anonymous Auth
Set-WebConfigurationProperty -PSPath "IIS:\Sites\$SiteName" `
    -Filter "system.webServer/security/authentication/anonymousAuthentication" `
    -Name "enabled" -Value "True"

# --- 10. Start containers ---
Write-Host "Starting Docker containers..."
docker run -d --name grafana -p 3000:3000 grafana/grafana
docker run -d --name n8n -p 5678:5678 n8nio/n8n

Write-Host "`n----- Deployment Complete -----"
Write-Host "Minerva Platform should now be accessible at: http://localhost:$Port"
Write-Host "`nServices running on:"
Write-Host "  - Grafana: http://localhost:3000"
Write-Host "  - n8n:    http://localhost:5678"
Write-Host "`nRoot directory: $RootPath"
Write-Host "IIS directory: $SitePath"