# Minerva Platform

A streamlined home lab dashboard that provides easy access to Grafana monitoring and n8n automation services.

## Overview

Minerva Platform is a simple, elegant web interface that centralizes access to:
- Grafana (data visualization and monitoring)
- n8n (workflow automation)

## Prerequisites

- Windows Server or Windows 10/11 with IIS installed
- PowerShell 5.1 or higher
- Docker Desktop
- IIS Web Administration module
- Administrator privileges

## Installation

1. Clone this repository:
```bash
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

## Default Port Configuration

- Main Interface: http://localhost:8500
- Grafana: http://localhost:3000
- n8n: http://localhost:5678

## Directory Structure

```
Minerva/
├── apps/
├── css/
│   └── styles.css
├── images/
│   └── frontpage.jpg
└── scripts/
```

## Features

- Responsive design
- Animated UI elements
- New-tab service launching
- Container management
- IIS configuration

## Troubleshooting

1. If the site doesn't load:
   - Verify IIS is running
   - Check the port isn't in use
   - Ensure you have admin privileges

2. If containers don't start:
   - Verify Docker Desktop is running
   - Check if ports 3000 or 5678 are available
   - Review Docker logs: `docker logs grafana` or `docker logs n8n`

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
