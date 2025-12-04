# Avina Interactive Installation

This directory contains the master script for deploying a new Avina environment.

## Overview

The `install.sh` script is an all-in-one tool that automates the entire setup process, including:
-   System preparation (APT configuration, Docker installation).
-   Interactive prompts for environment details (domain, passwords).
-   Deployment of the Avina project files to `/srv/avina`.
-   Automatic generation of the `.env` configuration file.
-   Automated management of user groups (`docker`, `avina-admins`).
-   Conditional setup of Nginx for either HTTP or HTTPS.
-   Launching the full Docker Compose stack.

## How to Run

1.  **Install Git and Clone Project:**
    ```bash
    sudo apt-get update && sudo apt-get install git -y
    cd ~
    git clone https://github.com/quamm-ai/Avina-AI.git
    ```

2.  **Prepare SSL Certificates (CRITICAL Step):**
    If you are deploying with HTTPS (Recommended), you must prepare your certificates *before* running the installer.
    
    **A. Create the Full Chain:**
    Nginx requires the full certificate chain (Server Cert + Root CA) in a single file.
    ```bash
    # Combine your server certificate and root CA
    cat server.crt rootCA.pem > fullchain.pem
    ```
    
    **B. Place Files:**
    Copy your files to the `ssl/` directory in the cloned repo:
    ```bash
    cp fullchain.pem ~/Avina-AI/ssl/
    cp server.key ~/Avina-AI/ssl/
    ```

3.  **Navigate and Execute:**
    ```bash
    cd ~/Avina-AI/install/
    chmod +x install.sh
    sudo ./install.sh
    ```

4.  **Follow Prompts:**
    Answer the questions to configure your environment.

## Post-Installation Requirements

### 1. Client-Side Trust
For internal networks using a private Certificate Authority (CA):
-   **Download the Root CA**: Get the `rootCA.pem` file from your IT team or the server.
-   **Install on Windows**:
    1.  Rename `rootCA.pem` to `rootCA.crt`.
    2.  Double-click and select "Install Certificate".
    3.  Choose **"Current User"** -> **"Place all certificates in the following store"** -> **"Trusted Root Certification Authorities"**.
    4.  Restart your browser.

### 2. User Permissions
All users granted administrative access must **log out and log back in** for `docker` group permissions to take effect.
