#!/bin/bash

# ==============================================================================
# Avina Interactive Environment Setup & Deployment Script
#
# This script prepares a Debian-based Linux system, asks for configuration
# details, deploys the Avina project files, and launches the Docker stack.
# It is designed to be the single entry point for setting up a new environment.
#
# USAGE:
# 1. Copy the entire Avina project folder to the target server.
# 2. cd into the 'install' directory.
# 3. Run with sudo: sudo ./install.sh
# ==============================================================================

# --- Shell Setup ---
# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration & Constants ---
AVINA_DIR="/srv/avina"
AVINA_GROUP="avina-admins"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
PROJECT_ROOT_SRC="$(dirname "$SCRIPT_DIR")"

# --- Helper Functions ---
# Color codes for output
C_BLUE='\033[0;34m'
C_GREEN='\033[0;32m'
C_YELLOW='\033[0;33m'
C_RED='\033[0;31m'
C_NONE='\033[0m'

info() {
    echo -e "${C_BLUE}INFO:${C_NONE} $1"
}

success() {
    echo -e "${C_GREEN}SUCCESS:${C_NONE} $1"
}

warn() {
    echo -e "${C_YELLOW}WARNING:${C_NONE} $1"
}

error() {
    echo -e "${C_RED}ERROR:${C_NONE} $1" >&2
    exit 1
}

prompt_input() {
    local prompt_text="$1"
    local var_name="$2"
    local default_value="${3:-}"
    local prompt_suffix=""
    if [ -n "$default_value" ]; then
        prompt_suffix=" [default: $default_value]"
    fi
    read -p "$(echo -e "${C_YELLOW}❓ ${prompt_text}${prompt_suffix}: ${C_NONE}")" input
    eval "$var_name=\"${input:-$default_value}\""
}

prompt_password() {
    local prompt_text="$1"
    local var_name="$2"
    while true; do
        read -s -p "$(echo -e "${C_YELLOW}❓ ${prompt_text}: ${C_NONE}")" pass1
        echo
        read -s -p "$(echo -e "${C_YELLOW}❓ Confirm ${prompt_text}: ${C_NONE}")" pass2
        echo
        if [ "$pass1" == "$pass2" ]; then
            if [ -z "$pass1" ]; then
                warn "Password cannot be empty. Please try again."
            else
                eval "$var_name=\"$pass1\""
                break
            fi
        else
            warn "Passwords do not match. Please try again."
        fi
    done
}


# --- Sanity Checks ---
if [ "$EUID" -ne 0 ]; then
  error "This script must be run with sudo privileges."
fi

# ==============================================================================
# --- PART 1: SYSTEM PREPARATION ---
# ==============================================================================
info "Starting Part 1: System Preparation..."

info "Configuring APT to use main Ubuntu HTTPS repository..."
if [ -f /etc/apt/sources.list.d/ubuntu.sources ]; then
    sed -i 's#https://azure.archive.ubuntu.com/ubuntu/#https://archive.ubuntu.com/ubuntu/#g' /etc/apt/sources.list.d/ubuntu.sources
    sed -i 's#URIs: http://#URIs: https://#g' /etc/apt/sources.list.d/ubuntu.sources
fi

info "Cleaning APT cache..."
apt-get clean > /dev/null
rm -rf /var/lib/apt/lists/*

info "Installing Docker Engine..."
apt-get update
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# --- Install Docker Compose (if not installed as a plugin) ---
if ! docker compose version &>/dev/null; then
    info "Docker Compose plugin not found, installing standalone..."
    LATEST_COMPOSE_VERSION=$(curl -s https://api.github.com/repos/docker/compose/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
    mkdir -p $DOCKER_CONFIG/cli-plugins
    curl -SL https://github.com/docker/compose/releases/download/$LATEST_COMPOSE_VERSION/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
    chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
    # Make it available for all users
    if [ -d "/usr/local/lib/docker/cli-plugins" ]; then
        ln -sfn $DOCKER_CONFIG/cli-plugins/docker-compose /usr/local/lib/docker/cli-plugins/docker-compose
    fi
fi

success "Docker installed successfully."

info "Creating shared group '$AVINA_GROUP' and project directory '$AVINA_DIR'..."
if ! getent group "$AVINA_GROUP" >/dev/null; then
    groupadd "$AVINA_GROUP"
fi
if [ ! -d "$AVINA_DIR" ]; then
    mkdir -p "$AVINA_DIR"
fi
success "System preparation complete."

# ==============================================================================
# --- PART 2: INTERACTIVE CONFIGURATION ---
# ==============================================================================
info "Starting Part 2: Interactive Configuration..."

# --- Ask for environment details ---
while true; do
    prompt_input "Enter environment type (qa/prod)" ENV_TYPE "qa"
    case "$ENV_TYPE" in
        qa|prod) break;;
        *) warn "Invalid selection. Please enter 'qa' or 'prod'.";;
    esac
done

prompt_input "Enter client identifier (e.g., nkr)" CLIENT_ID "nkr"
prompt_input "Enter top-level domain (e.g., co.il)" TLD "co.il"
DEFAULT_DOMAIN="${ENV_TYPE}.avina.${CLIENT_ID}.${TLD}"
prompt_input "Full domain for the service" DOMAIN "$DEFAULT_DOMAIN"
prompt_input "Email for SSL certificate alerts" CERTBOT_EMAIL "devops@${CLIENT_ID}.${TLD}"
prompt_password "MongoDB root password" MONGO_ROOT_PASSWORD

# --- Auto-detect values ---
CURRENT_UID=$(id -u "$SUDO_USER")
CURRENT_GID=$(id -g "$SUDO_USER")
info "Detected UID=${CURRENT_UID} and GID=${CURRENT_GID} for user '$SUDO_USER'."

# --- Finalize variables based on environment ---
if [ "$ENV_TYPE" == "qa" ]; then
    MONGO_ROOT_USER="AvinaQA"
    MONGO_DATABASE="avina_qa"
    COMPOSE_PROJECT_NAME="avina_qa"
else
    MONGO_ROOT_USER="AvinaProd"
    MONGO_DATABASE="avina_prod"
    COMPOSE_PROJECT_NAME="avina_prod"
fi
success "Configuration gathered."


# ==============================================================================
# --- PART 3: PROJECT DEPLOYMENT & USER MANAGEMENT ---
# ==============================================================================
info "Starting Part 3: Project Deployment..."

info "Copying project files to $AVINA_DIR..."
# Use rsync to copy the entire project structure (including docker-compose files,
# nginx config, browser/, n8n/, etc.) to the deployment directory.
# It excludes development-specific files and local .env files.
rsync -a --exclude='.git' --exclude='notes' --exclude='.idea' --exclude='*.env' "$PROJECT_ROOT_SRC/" "$AVINA_DIR/"
success "Project files deployed."

info "Creating .env file in $AVINA_DIR..."
# --- Determine which NGINX config to use ---
# Check if both .crt and .key files exist in the ssl/ directory.
if ls "${AVINA_DIR}/ssl/"*.crt &>/dev/null && ls "${AVINA_DIR}/ssl/"*.key &>/dev/null; then
    info "SSL certificate and key found. Configuring NGINX for HTTPS."
    NGINX_CONFIG_FILE="nginx.conf"
else
    warn "SSL certificate not found. Configuring NGINX for HTTP-only access."
    warn "This is NOT secure for production. Please add your SSL certs to the 'ssl/' directory."
    NGINX_CONFIG_FILE="nginx-http.conf"
fi

cat << EOF > "${AVINA_DIR}/.env"
# This file was auto-generated by the install.sh script
COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME}

# --- NGINX Configuration ---
NGINX_CONFIG_FILE=${NGINX_CONFIG_FILE}

# --- Core Settings ---
DOMAIN=${DOMAIN}
CERTBOT_EMAIL=${CERTBOT_EMAIL}

# --- MongoDB ---
MONGO_ROOT_USER=${MONGO_ROOT_USER}
MONGO_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
MONGO_DATABASE=${MONGO_DATABASE}

# --- Common ---
N8N_UID=${CURRENT_UID}
N8N_GID=${CURRENT_GID}
EOF
success ".env file created."

info "Setting final directory permissions..."
chown -R "$SUDO_USER":"$AVINA_GROUP" "$AVINA_DIR"
chmod -R 2775 "$AVINA_DIR"

info "Adding users to required groups..."
prompt_input "Enter other admin usernames (comma-separated, no spaces)" OTHER_ADMINS
ADMINS=$(echo "$SUDO_USER,$OTHER_ADMINS" | tr ',' ' ')
for user in $ADMINS; do
    if id "$user" &>/dev/null; then
        usermod -aG "$AVINA_GROUP" "$user"
        usermod -aG docker "$user"
        info "Added user '$user' to '$AVINA_GROUP' and 'docker' groups."
    else
        warn "User '$user' does not exist. Skipping."
    fi
done

# ==============================================================================
# --- PART 4: SERVICE LAUNCH ---
# ==============================================================================
info "Starting Part 4: Initial Service Launch..."

cd "$AVINA_DIR"

info "Launching the full Avina stack in the background..."

# Run the unified docker-compose file
docker compose up -d
success "All services have been started."

# ==============================================================================
# --- FINAL INSTRUCTIONS ---
# ==============================================================================
echo
echo -e "${C_GREEN}=================================================="
echo -e "✅ DEPLOYMENT COMPLETE"
echo -e "==================================================${C_NONE}"
echo
echo "The Avina cluster is now running."
echo "You should be able to access n8n at: https://${DOMAIN}/n8n/"
echo
warn "!!! IMPORTANT FINAL STEP !!!"
warn "All administrative users, including '$SUDO_USER', MUST log out"
warn "and log back in for their new 'docker' group permissions to take effect."
echo
