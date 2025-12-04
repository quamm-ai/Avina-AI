# Avina Cluster Project

This project contains the complete infrastructure-as-code and deployment automation for the Avina cluster. It is designed for repeatable, secure, and flexible deployments across multiple environments and clients.

## Project Structure

-   `install/`: Contains the master interactive installation script and its documentation.
-   `docker-compose.yml`: Defines all infrastructure and application services (Nginx, MongoDB, n8n).
-   `nginx/`: Contains Nginx configurations for secure HTTPS mode with a custom build process.
-   `ssl/`: A placeholder for your custom SSL certificate and private key.
-   `data/`: Stores persistent data volumes for services like MongoDB and n8n.
-   `environments/`: Holds configuration templates for different deployment environments.
-   `n8n/`: Contains n8n custom extensions and related configurations.
-   `browser/`: Holds directories for file `uploads` and `downloads` used by services.
-   `www/`: Contains the template for the dynamic landing page.
-   `enable-ssl.sh`: A utility script to apply configuration changes and rebuild services.

## Database Configuration
This project uses a hybrid database setup:
-   **n8n** uses **SQLite** for its internal database, which is simple and officially supported. The database file is persisted in the `data/n8n` directory.
-   **MongoDB** is included and available for any custom applications you choose to add to the cluster.

## Deployment
The primary method for deploying a new Avina environment is through the interactive installation script. This script handles system preparation, Docker installation, project deployment, and service configuration in one automated flow.

### SSL Configuration (CRITICAL)
For secure internal deployments, you must use a valid SSL certificate. Since we use internal Certificate Authorities (CAs), specific steps are required:

1.  **Server-Side (Linux)**:
    - You must provide the **Full Certificate Chain**.
    - Combine your server certificate (`server.crt`) and the Root CA certificate (`rootCA.pem`) into a single file:
      ```bash
      cat server.crt rootCA.pem > fullchain.pem
      ```
    - Place `fullchain.pem` and your private key (`server.key`) in the `/srv/avina/ssl/` directory.
    - **Important**: The certificate MUST have the **Subject Alternative Name (SAN)** field correctly populated with your domain (e.g., `DNS:qa.avina.nkr.co.il`). Modern browsers will reject certificates without this field.

2.  **Client-Side (Windows/Mac)**:
    - Users accessing the system must trust the **Root CA**.
    - Install the `rootCA.crt` (rename from `.pem`) into the **"Trusted Root Certification Authorities"** store on their local machine.

### Quick Start Guide

1.  **Connect to your VM and Install Git:**
    ```bash
    sudo apt-get update && sudo apt-get install git -y
    ```

2.  **Clone the Repository:**
    ```bash
    cd ~
    git clone https://github.com/quamm-ai/Avina-AI.git
    ```
    
3.  **Run the Installer:**
    ```bash
    cd ~/Avina-AI/install/
    chmod +x install.sh
    sudo ./install.sh
    ```

4.  **Follow the Prompts:**
    The script will guide you through configuring the environment.

### Manual Management
After the initial deployment, you can manage the stack from the deployment directory (`/srv/avina`) using standard Docker Compose commands.

-   **Apply Updates / Restart Services:**
    ```bash
    # This pulls new images and rebuilds the nginx container if config changed
    docker compose up -d --build --force-recreate
    ```

-   **View logs:**
    ```bash
    docker compose logs -f
    ```

## Security

-   **Least Privilege:** The setup creates a dedicated `avina-admins` group for file permissions and relies on the `docker` group for container management.
-   **Secrets Management:** All sensitive values are managed in a `.env` file on the server.
-   **Network Security:** Ensure your firewall only allows ports 80 and 443.
