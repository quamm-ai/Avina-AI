#!/bin/bash

# ==============================================================================
# Enable SSL Script for Avina
#
# This script switches the Nginx configuration from the temporary HTTP setup
# to the permanent, secure HTTPS setup. It should be run after placing the
# SSL certificate (.crt) and private key (.key) into the /srv/avina/ssl directory.
#
# USAGE: sudo ./enable-ssl.sh
# ==============================================================================

set -e

AVINA_DIR="/srv/avina"
ENV_FILE="${AVINA_DIR}/.env"

# --- Sanity Checks ---
if [ "$EUID" -ne 0 ]; then
  echo "ERROR: This script must be run with sudo privileges."
  exit 1
fi

if [ ! -d "$AVINA_DIR" ]; then
    echo "ERROR: Deployment directory '$AVINA_DIR' not found."
    exit 1
fi

# Check for either a .crt or .pem file, along with a .key file
if ! (ls "${AVINA_DIR}/ssl/"*.crt &>/dev/null || ls "${AVINA_DIR}/ssl/"*.pem &>/dev/null) || ! ls "${AVINA_DIR}/ssl/"*.key &>/dev/null; then
    echo "ERROR: SSL certificate (.crt or .pem) and/or private key (.key) not found in '${AVINA_DIR}/ssl/'."
    echo "Please place your certificate files in the correct location before running this script."
    exit 1
fi

echo "INFO: SSL certificate and key found."

# --- Update .env file ---
if [ -f "$ENV_FILE" ]; then
    echo "INFO: Updating .env file to use 'nginx.conf'..."
    # Use sed to replace the NGINX_CONFIG_FILE variable.
    # It works whether the variable exists or not.
    if grep -q "NGINX_CONFIG_FILE=" "$ENV_FILE"; then
        sed -i "s/NGINX_CONFIG_FILE=.*/NGINX_CONFIG_FILE=nginx.conf/" "$ENV_FILE"
    else
        echo "NGINX_CONFIG_FILE=nginx.conf" >> "$ENV_FILE"
    fi
else
    echo "ERROR: .env file not found at '$ENV_FILE'."
    exit 1
fi

echo "INFO: Restarting Avina stack with new SSL configuration..."
cd "$AVINA_DIR"
docker compose up -d --force-recreate nginx

echo "✅ SUCCESS: SSL has been enabled. Nginx has been restarted."
echo "Your Avina instance should now be available via HTTPS."
