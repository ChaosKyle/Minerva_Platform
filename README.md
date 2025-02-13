# Minerva Platform
A streamlined home lab dashboard that provides easy access to Grafana monitoring and n8n automation services.

## Overview
Minerva Platform is a simple, elegant web interface that centralizes access to:
* Grafana (data visualization and monitoring)
* n8n (workflow automation)

## Deployment Options

### Option 1: Windows with IIS (PowerShell Deployment)

#### Prerequisites
* Windows Server or Windows 10/11 with IIS installed
* PowerShell 5.1 or higher
* Docker Desktop
* IIS Web Administration module
* Administrator privileges

#### Installation
1. Clone this repository:
```powershell
git clone <your-repository-url>
cd minerva
```

2. Place your desired header image in:
```
C:\inetpub\wwwroot\Minerva\images\frontpage.jpg
```

3. Run the deployment script with administrator privileges:
```powershell
.\deploy.ps1
```

Optional parameters:
```powershell
.\deploy.ps1 -SiteName "MinervaPlatform" -SitePath "C:\inetpub\wwwroot\Minerva" -Port 8500
```

### Option 2: Cross-Platform Python Deployment

#### Prerequisites

##### macOS
1. Install Python 3:
```bash
brew install python@3.13
```

2. Install Docker Desktop:
- Download from [Docker Desktop for Mac](https://www.docker.com/products/docker-desktop)
- Install and start Docker Desktop

##### Windows
1. Install Python 3:
- Download from [Python.org](https://www.python.org/downloads/)
- Check "Add Python to PATH" during installation

2. Install Docker Desktop:
- Download from [Docker Desktop for Windows](https://www.docker.com/products/docker-desktop)
- Install and start Docker Desktop

#### Installation

##### macOS
```bash
python3 deploy.py
cd ~/minerva
./start.sh
```

##### Windows
```cmd
python deploy.py
cd %USERPROFILE%\minerva
start.bat
```

## Default Port Configuration
* Main Interface: http://localhost:8500
* Grafana: http://localhost:3000
* n8n: http://localhost:5678

## Directory Structure

### IIS Deployment
```
Minerva/
├── apps/
├── css/
│   └── styles.css
├── images/
│   └── frontpage.jpg
└── scripts/
```

### Python Deployment
```
~/minerva/
├── app.py              # Flask application
├── venv/              # Python virtual environment
└── start.sh/start.bat # Platform-specific start script
```

## Features
* Responsive design
* Animated UI elements
* New-tab service launching
* Container management
* Multiple deployment options (IIS or Flask)
* Cross-platform support

## Troubleshooting

### IIS Deployment
1. If the site doesn't load:
   * Verify IIS is running
   * Check the port isn't in use
   * Ensure you have admin privileges

### Python Deployment

#### macOS
1. If you get "command not found: python3":
```bash
brew unlink python@3.13 && brew link python@3.13
```

2. If you get permission errors:
```bash
# Choose option 2 when prompted to use alternative directory
python3 deploy.py
```

#### Windows
1. If Python isn't recognized:
- Verify Python is in PATH
- Try using `py` instead of `python`

2. If Docker isn't running:
- Open Docker Desktop from Start Menu
- Wait for the whale icon to stabilize

### Common Docker Issues
* Verify Docker Desktop is running
* Check if ports 3000 or 5678 are available
* Review Docker logs: `docker logs grafana` or `docker logs n8n`

## Contributing
1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License
This project is licensed under the MIT License - see the LICENSE file for details

## Support
For issues or questions, please open an issue in the repository.

## Security Notes
- Default ports (3000, 5678, 8500) should be available
- Docker Desktop must be running
- Services are accessible only from localhost by default
- Change default credentials after first login
- For IIS deployment, ensure proper Windows security settings
- For Python deployment, virtual environment provides isolation