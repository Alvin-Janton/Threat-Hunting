# **Information About This Folder**

This folder contains three items related to deploying and maintaining the Catalyst environment.

---

## 🛠️ setup_catalyst.sh & setup_catalyst.ps1

These scripts automates the full deployment of the Catalyst IR stack. They performs the following actions:

- Creates required directories, certificates, and configuration files  
- Generates the Nginx reverse proxy configuration  
- Builds multiple YAML configuration files for Docker services and Authelia  
- Updates `/etc/hosts` or `Winodws\System32\Drivers\etc\hosts` with DNS records for the Catalyst and Authelia hostnames  
- Creates a `.env` file containing all secret values used by the stack  
- Pulls the necessary Docker images and launches all containers  

If you want to modify or expand the scripts, feel free.  
This was my first time writing a scripts of this complexity, so there is definitely room for improvement and optimization.

---

## 🩺 **Troubleshooting.md**

This file will contain troubleshooting tips for cases where:

- Catalyst cannot be accessed  
- Certain services fail to launch  
- Containers fail health checks  
- DNS resolution or Nginx reverse proxying is not functioning  

