#!/bin/bash

# Set the working directory
REPO_DIR="/home/ubuntu/medusav1"
PM2_PROCESS_NAME="my-medusa-server"

# Navigate to the repository directory
cd "$REPO_DIR" || {
  echo "Directory not found: $REPO_DIR"
  exit 1
}

# Ensure the directory is a git repository
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Not a git repository: $REPO_DIR"
  exit 1
fi

# Fetch the latest changes
echo "Fetching the latest changes..."
git fetch origin || {
  echo "Failed to fetch changes."
  exit 1
}

# Check if there are new changes
if ! git diff --quiet HEAD origin/main; then
  echo "New changes detected. Pulling changes and restarting PM2 process..."

  # Pull the latest changes
  git pull origin main || {
    echo "Failed to pull changes."
    exit 1
  }

  echo "Installing dependencies with --legacy-peer-deps..."
  npm install --legacy-peer-deps || {
    echo "Failed to install dependencies."
    exit 1
  }

  # Check if the PM2 process is running
  if pm2 list | grep -q "$PM2_PROCESS_NAME"; then
    echo "Stopping PM2 process: $PM2_PROCESS_NAME"
    pm2 stop "$PM2_PROCESS_NAME" || {
      echo "Failed to stop PM2 process: $PM2_PROCESS_NAME"
      exit 1
    }
  fi

  # Start or restart the PM2 process
  echo "Starting PM2 process: $PM2_PROCESS_NAME"
  pm2 start "medusa start" --name "$PM2_PROCESS_NAME" || {
    echo "Failed to start PM2 process: $PM2_PROCESS_NAME"
    exit 1
  }
else
  echo "No new changes. Checking PM2 process status..."

  # Ensure the PM2 process is running
  if ! pm2 list | grep -q "$PM2_PROCESS_NAME"; then
    echo "PM2 process not found. Starting it now..."
    pm2 start "medusa start" --name "$PM2_PROCESS_NAME" || {
      echo "Failed to start PM2 process: $PM2_PROCESS_NAME"
      exit 1
    }
  else
    echo "PM2 process is already running: $PM2_PROCESS_NAME"
  fi
fi

echo "Script execution completed."
