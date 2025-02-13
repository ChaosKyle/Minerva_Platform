#!/bin/bash

# Default parameters
SITE_NAME="Minerva"
ROOT_PATH="$HOME/Minerva"
PORT=8500

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        --site-name) SITE_NAME="$2"; shift ;;
        --root-path) ROOT_PATH="$2"; shift ;;
        --port) PORT="$2"; shift ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

echo "----- Starting deployment for '$SITE_NAME' on port $PORT -----"

# Check if running as root and exit if true
if [ "$EUID" -eq 0 ]; then
    echo "ERROR: Please do not run this script as root or with sudo"
    exit 1
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "Homebrew is already installed"
fi

# Check for and install required packages
echo "Checking required packages..."
PACKAGES=(nginx docker)

for package in "${PACKAGES[@]}"; do
    if ! brew list $package &>/dev/null; then
        echo "Installing $package..."
        brew install $package
    else
        echo "$package is already installed"
    fi
done

# Ensure nginx is running under current user
if ! brew services list | grep nginx | grep started >/dev/null; then
    echo "Starting nginx..."
    brew services start nginx
fi

# Start Docker service if it's not running
if ! docker info &>/dev/null; then
    echo "Starting Docker service..."
    open -a Docker
    # Wait for Docker to start
    echo "Waiting for Docker to start..."
    while ! docker info &>/dev/null; do
        sleep 1
    done
fi

# Clean up existing resources
echo "Cleaning up existing resources..."
docker stop grafana n8n 2>/dev/null
docker rm grafana n8n 2>/dev/null

# Create root directory structure
echo "Creating root directory structure..."
DIRS=(
    "$ROOT_PATH"
    "$ROOT_PATH/apps"
    "$ROOT_PATH/css"
    "$ROOT_PATH/images"
    "$ROOT_PATH/scripts"
)

for dir in "${DIRS[@]}"; do
    if [ ! -d "$dir" ]; then
        echo "Creating directory: $dir"
        mkdir -p "$dir"
    else
        echo "Directory already exists: $dir"
    fi
done

# Create basic HTML
cat > "$ROOT_PATH/index.html" << 'EOL'
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
EOL

# Create enhanced CSS (same CSS content as before...)
cat > "$ROOT_PATH/css/styles.css" << 'EOL'
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
    0% { background-position: 0% 50%; }
    50% { background-position: 100% 50%; }
    100% { background-position: 0% 50%; }
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
EOL

# Set up nginx configuration
echo "Setting up nginx configuration..."
NGINX_CONF_DIR="$(brew --prefix)/etc/nginx/servers"
mkdir -p "$NGINX_CONF_DIR"

# Create nginx configuration file
cat > "$NGINX_CONF_DIR/minerva.conf" << EOL
server {
    listen $PORT;
    server_name localhost;

    root $ROOT_PATH;
    index index.html;

    location / {
        try_files \$uri \$uri/ =404;
    }
}
EOL

# Restart nginx
echo "Restarting nginx..."
brew services restart nginx

# Start Docker containers
echo "Starting Docker containers..."
docker run -d --name grafana -p 3000:3000 grafana/grafana
docker run -d --name n8n -p 5678:5678 n8nio/n8n

echo -e "\n----- Deployment Complete -----"
echo "Minerva Platform should now be accessible at: http://localhost:$PORT"
echo -e "\nServices running on:"
echo "  - Grafana: http://localhost:3000"
echo "  - n8n:    http://localhost:5678"
echo -e "\nRoot directory: $ROOT_PATH"