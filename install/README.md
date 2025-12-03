# Avina Interactive Installation

This directory contains the master script for deploying a new Avina environment.

## Overview

The `install.sh` script is an all-in-one tool that automates the entire setup process, including:
-   System preparation (APT configuration, Docker installation).
-   Interactive prompts for environment details (domain, passwords, users).
-   Deployment of the Avina project files to `/srv/avina`.
-   Automatic generation of the `.env` configuration file.
-   Automated management of user groups (`docker`, `avina-admins`).
-   Acquisition of the initial SSL certificate from Let's Encrypt.
-   Launching the full Docker Compose stack.

This script is the recommended and primary method for all new deployments.

## How to Run

1.  **Copy Project:**
    Ensure the entire Avina project directory (the parent of this `install` directory) is present on the target Ubuntu server.

2.  **Navigate and Execute:**
    Change into this directory and run the script with `sudo` privileges.

    ```bash
    cd /path/to/project/install
    sudo ./install.sh
    ```

3.  **Follow Prompts:**
    Answer the questions provided by the script to configure your environment.

## Post-Installation

Upon successful completion, the script will provide a URL to access the running `n8n` service.

**Crucially, all users who were granted administrative access (including the user who ran the script) must log out and log back in** for their new `docker` group permissions to take effect.
