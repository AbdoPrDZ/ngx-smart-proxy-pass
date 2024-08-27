#!/bin/bash

# Script to install the Smart-Proxy-Pass project folder as a symbolic link in the lua-scripts folder
# This script will also set the permissions for the project folder and its subfolders
# Usage: ./install.sh <project_path> [lua_scripts_path] [log_path] [engine]
#   project_path: Path to the project directory
#   lua_scripts_path: (Optional) Path to the lua-scripts directory (default: /etc/nginx/lua-scripts)
#   log_path: (Optional) Path to the logs directory (default: /var/log/smart-proxy-pass.log)
#   engine: (Optional) The server engine you use (default: nginx)

VERSION="1.0.3"

# Function to display usage information
usage() {
  echo "Smart-Proxy-Pass Install Script"
  echo "Version: $VERSION"
  echo ""
  echo "Usage: $0 <project_path> [lua_scripts_path] [log_path] [engine]"
  echo "  project_path: Path to the project directory"
  echo "  lua_scripts_path: (Optional) Path to the lua-scripts directory (default: /etc/nginx/lua-scripts)"
  echo "  log_path: (Optional) Path to the logs directory (default: /var/log/smart-proxy-pass.log)"
  echo "  engine: (Optional) The server engine you use (default: nginx)"
  exit 1
}

# Check if the first argument is not provided
if [ -z "$1" ]; then
  echo "Error: Project path is required"
  usage
fi

# Display help
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
  usage
fi

# Display version
if [ "$1" == "--version" ] || [ "$1" == "-v" ]; then
  echo "Version: $VERSION"
  exit 0
fi

# Get the project path
project_path=$1

# Get lua-scripts path (default: "/etc/nginx/lua-scripts")
lua_scripts_path=${2:-"/etc/nginx/lua-scripts"}

# Check if the project folder exists
if [ ! -d "$project_path" ]; then
  echo "Failed to find the project folder $project_path"
  exit 1
fi

# Check if the lua-scripts folder exists
if [ ! -d "$lua_scripts_path" ]; then
  echo "Failed to find the lua-scripts folder $lua_scripts_path"
  exit 1
fi

link_path="$lua_scripts_path/spp"
# Link the folder to the nginx folder
if [ ! -L "$link_path" ]; then
  echo "Creating symbolic link $link_path -> $project_path"
  sudo ln -s "$project_path" "$link_path"
else
  echo "Symbolic link already exists at $link_path"
fi

# Allow nginx to read the folder
echo "Setting permissions for Nginx access"
sudo chmod 755 "$(dirname "$project_path")"
sudo chmod 755 "$project_path"
sudo chown -R www-data:www-data "$project_path"

# Allow vscode to write in the folder
echo "Setting permissions for VS Code access"
sudo chmod -R 775 "$project_path"
sudo chown -R "$(whoami)":"$(whoami)" "$project_path"

# Get the log path (default: "/var/log/smart-proxy-pass.log")
log_path=${4:-"/var/log/smart-proxy-pass.log"}
# Check if the log file is exists
if [ ! -f "$log_path" ]; then
  echo "Warning: Log file does not exist at $log_path"
  # Create the log file
  echo "Creating log file at $log_path"
  # Check if the log folder exists
  log_folder=$(dirname "$log_path")
  if [ ! -d "$log_folder" ]; then
    echo "Creating log folder at $log_folder"
    sudo mkdir -p "$log_folder"
  fi
  # Create the log file
  sudo touch "$log_path"
fi

# Set write permissions for the log file
echo "Setting write permissions for log file"
sudo chmod 644 "$log_path"
sudo chown www-data:www-data "$log_path"

# Reload server engine
echo "Reloading server engine"
engine=${4:-"nginx"}
sudo service $engine reload

# Display success message
echo "Script completed successfully"
