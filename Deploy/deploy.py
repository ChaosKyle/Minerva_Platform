#!/usr/bin/env python3
"""
Minerva Platform Deployment Script
This script handles the complete deployment of the Minerva platform, including:
- Virtual environment creation
- Dependencies installation
- File creation
- Docker container management
"""

import os
import subprocess
import sys
import venv
import shutil
from pathlib import Path

# Flask application code that will be written to app.py
FLASK_APP_CODE = '''from flask import Flask, render_template_string
import subprocess
import os

app = Flask(__name__)

HTML_TEMPLATE = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Minerva Platform</title>
    <style>
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
            color: #2c3e50;
            text-transform: uppercase;
            letter-spacing: 4px;
            margin-bottom: 30px;
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
            transition: all 0.3s ease;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            position: relative;
        }
        .card:hover {
            transform: translateY(-5px);
            box-shadow: 0 8px 15px rgba(0,0,0,0.2);
        }
        .status {
            position: absolute;
            top: 10px;
            right: 10px;
            width: 10px;
            height: 10px;
            border-radius: 50%;
        }
        .status.running { background-color: #2ecc71; }
        .status.stopped { background-color: #e74c3c; }
        span {
            font-size: 24px;
            font-weight: 600;
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1 class="title">Minerva</h1>
        </div>
        <div class="grid">
            <a href="http://localhost:3000" class="card" target="_blank">
                <div class="status {{ grafana_status }}"></div>
                <span>Grafana</span>
            </a>
            <a href="http://localhost:5678" class="card" target="_blank">
                <div class="status {{ n8n_status }}"></div>
                <span>n8n</span>
            </a>
        </div>
    </div>
</body>
</html>
"""

def is_container_running(container_name):
    """Check if a Docker container is running."""
    try:
        result = subprocess.run(
            ['docker', 'ps', '--filter', f'name={container_name}', '--format', '{{{{.Names}}}}'],
            capture_output=True,
            text=True
        )
        return container_name in result.stdout
    except:
        return False

@app.route('/')
def index():
    """Render the main page with service status indicators."""
    grafana_status = 'running' if is_container_running('grafana') else 'stopped'
    n8n_status = 'running' if is_container_running('n8n') else 'stopped'
    
    return render_template_string(
        HTML_TEMPLATE,
        grafana_status=grafana_status,
        n8n_status=n8n_status
    )

def start_containers():
    """Start the required Docker containers if they're not running."""
    containers = {
        'grafana': 'grafana/grafana',
        'n8n': 'n8nio/n8n'
    }
    
    for name, image in containers.items():
        if not is_container_running(name):
            try:
                subprocess.run(['docker', 'rm', name], capture_output=True)
                subprocess.run([
                    'docker', 'run', '-d',
                    '--name', name,
                    '-p', f'{3000 if name == "grafana" else 5678}:{"3000" if name == "grafana" else "5678"}',
                    image
                ])
                print(f"Started {name} container")
            except Exception as e:
                print(f"Error starting {name}: {e}")

if __name__ == '__main__':
    start_containers()
    app.run(host='0.0.0.0', port=8500)
'''

def check_docker():
    """Verify Docker is installed and running."""
    try:
        subprocess.run(['docker', '--version'], check=True, capture_output=True)
        subprocess.run(['docker', 'info'], check=True, capture_output=True)
        return True
    except subprocess.CalledProcessError:
        print("ERROR: Docker is not running or not installed")
        print("Please install Docker Desktop from: https://www.docker.com/products/docker-desktop")
        return False
    except FileNotFoundError:
        print("ERROR: Docker is not installed")
        print("Please install Docker Desktop from: https://www.docker.com/products/docker-desktop")
        return False

def setup_venv(app_dir):
    """Create and configure virtual environment."""
    venv_dir = os.path.join(app_dir, 'venv')
    print(f"Creating virtual environment in {venv_dir}")
    venv.create(venv_dir, with_pip=True)
    
    # Get the path to the virtual environment's Python and pip
    if sys.platform == 'win32':
        venv_python = os.path.join(venv_dir, 'Scripts', 'python.exe')
        venv_pip = os.path.join(venv_dir, 'Scripts', 'pip.exe')
    else:
        venv_python = os.path.join(venv_dir, 'bin', 'python')
        venv_pip = os.path.join(venv_dir, 'bin', 'pip')
    
    # Install required packages
    subprocess.run([venv_pip, 'install', 'flask'], check=True)
    
    return venv_python

def create_app_files(app_dir):
    """Create necessary application files."""
    # Create app.py
    with open(os.path.join(app_dir, 'app.py'), 'w') as f:
        f.write(FLASK_APP_CODE)
    
    # Create start script
    if sys.platform == 'win32':
        start_script = os.path.join(app_dir, 'start.bat')
        script_content = f'@echo off\ncall venv\\Scripts\\activate\npython app.py'
    else:
        start_script = os.path.join(app_dir, 'start.sh')
        script_content = '#!/bin/bash\nsource venv/bin/activate\npython app.py'
    
    with open(start_script, 'w') as f:
        f.write(script_content)
    
    # Make start script executable on Unix-like systems
    if sys.platform != 'win32':
        os.chmod(start_script, 0o755)

def main():
    """Main deployment function."""
    print("----- Starting Minerva Deployment -----")
    
    # Check Docker first
    if not check_docker():
        sys.exit(1)
    
    # Set up application directory
    app_dir = os.path.expanduser('~/minerva')
    if os.path.exists(app_dir):
        print(f"Existing installation found at {app_dir}")
        try:
            # Try to remove the directory
            shutil.rmtree(app_dir)
        except PermissionError:
            # If permission error, ask user what to do
            response = input(f"Cannot remove existing directory. Choose an option:\n"
                           f"1. Try with sudo (requires password)\n"
                           f"2. Use a different directory\n"
                           f"3. Exit\n"
                           f"Enter choice (1-3): ")
            
            if response == "1":
                try:
                    subprocess.run(['sudo', 'rm', '-rf', app_dir], check=True)
                except subprocess.CalledProcessError:
                    print("Failed to remove directory even with sudo. Exiting.")
                    sys.exit(1)
            elif response == "2":
                app_dir = os.path.expanduser('~/Documents/minerva')
                print(f"Using alternative directory: {app_dir}")
            else:
                print("Exiting deployment.")
                sys.exit(1)
    
    try:
        os.makedirs(app_dir, exist_ok=True)
    except PermissionError:
        print(f"Cannot create directory at {app_dir}")
        app_dir = os.path.expanduser('~/Documents/minerva')
        print(f"Trying alternative location: {app_dir}")
        os.makedirs(app_dir, exist_ok=True)
    print(f"Created application directory: {app_dir}")
    
    # Set up virtual environment
    try:
        venv_python = setup_venv(app_dir)
    except Exception as e:
        print(f"Error setting up virtual environment: {e}")
        sys.exit(1)
    
    # Create application files
    create_app_files(app_dir)
    
    print("\n----- Deployment Complete -----")
    print(f"Application installed in: {app_dir}")
    print("\nTo start Minerva:")
    if sys.platform == 'win32':
        print(f"cd {app_dir} && start.bat")
    else:
        print(f"cd {app_dir} && ./start.sh")
    
    print("\nMinerva will be accessible at: http://localhost:8500")
    print("Services running on:")
    print("  - Grafana: http://localhost:3000")
    print("  - n8n:    http://localhost:5678")

if __name__ == '__main__':
    main()