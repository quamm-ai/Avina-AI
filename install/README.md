# Avina Interactive Installation

This directory contains the master script for deploying a new Avina environment.

## Overview

The `install.sh` script is an all-in-one tool that automates the entire setup process, including:
-   System preparation (APT configuration, Docker installation).
-   Interactive prompts for environment details (domain, passwords).
-   Deployment of the Avina project files to `/srv/avina`.
-   Automatic generation of the `.env` configuration file.
-   Automated management of user groups (`docker`, `avina-admins`).
-   Conditional setup of Nginx for either HTTP or HTTPS based on the presence of SSL certificates.
-   Launching the full Docker Compose stack.

This script is the recommended and primary method for all new deployments.

## How to Run

1.  **Install Git and Clone Project:**
    On a clean Ubuntu server, connect via SSH, install `git`, and clone the repository into your home directory.
    ```bash
    sudo apt-get update && sudo apt-get install git -y
    cd ~
    git clone https://github.com/quamm-ai/Avina-AI.git
    ```

2.  **(Optional) Add SSL Certificate:**
    If you want to start in secure HTTPS mode, place your SSL certificate (`.crt`) and private key (`.key`) in the `ssl/` directory now.
    ```bash
    cp /path/to/your/certificate.crt ~/Avina-AI/ssl/
    cp /path/to/your/private.key ~/Avina-AI/ssl/
    ```

3.  **Navigate and Execute:**
    Change into this directory, make the script executable, and then run it with `sudo` privileges. The script will handle moving the project to its final destination (`/srv/avina`).
    ```bash
    cd ~/Avina-AI/install/
    chmod +x install.sh
    sudo ./install.sh
    ```

4.  **Follow Prompts:**
    Answer the questions provided by the script to configure your environment.

## Post-Installation

Upon successful completion, the script will provide a URL to access the running `n8n` service. This will be an `http://` link if you installed without SSL, or an `https://` link if you provided certificates.

**Crucially, all users who were granted administrative access (including the user who ran the script) must log out and log back in** for their new `docker` group permissions to take effect.
