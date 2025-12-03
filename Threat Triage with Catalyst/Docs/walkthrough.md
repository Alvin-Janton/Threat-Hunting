# 📝 Preliminary Information

Before beginning this project, I installed the Docker Engine (Docker + Docker Compose), executed a custom installation script to launch the required containers, and accessed Catalyst to begin generating incidents, adding observables, running enrichments, and documenting the full investigation workflow.

---

## 🌐 Environment

This project is conducted inside **Catalyst**, a free and open-source incident response platform built to support SOC and DFIR workflows. Catalyst enables analysts to:

- Create and manage incident records  
- Add observables (IoCs) and run automated enrichments  
- Build detailed evidence timelines  
- Write notes and document analytical decisions  
- Export reports for stakeholders  

All steps of both investigations were performed within this unified interface.

---

## 📂 Data Sources

All indicators and investigative details used in this project originate from two prior threat-hunting investigations I completed:

- **Threat Hunting with Splunk — SolarWinds IOC correlation**  
- **Threat Hunting with Python — AWS CloudTrail exfiltration case**

These projects supplied the IoCs and supporting artifacts used to construct each Catalyst incident, including:

- Malicious IP addresses  
- Principal ID and temporary access-key metadata  
- Attacker user-agent strings  
- S3 object paths associated with exfiltration  
- Additional identifiers required for correlation and enrichment  

---

## 🧭 If You Want to Follow Along

If you're new to Catalyst, Docker, or incident-response platforms, the following resources will help you get started:

### 📘 Catalyst Handbook  
Installation, configuration, incident creation, observables, enrichment, and UI usage.  
➡️ https://catalyst.security-brewery.com/docs/category/catalyst-handbook

### 💻 Catalyst GitHub Repository  
Source code, releases, templates, and deployment examples.  
➡️ https://github.com/SecurityBrewery/catalyst

### 🐳 Docker Installation Guide  
Official instructions for installing the Docker Engine.  
➡️ https://docs.docker.com/engine/install/

### 🎥 Beginner-Friendly Docker Tutorial (Video)  
A visual introduction to containers and Docker workflow.  
➡️ https://youtu.be/DQdB7wFEygo?si=V91KY5BbZPgvF7p3

---

## 🖥️ About Operating Systems (Important Note for Readers)

This walkthrough is written with a **Linux/Ubuntu environment** in mind.  
The full incident-response version of Catalyst (the version used in this project) runs as a **multi-container Docker stack**, and its deployment scripts are written in **Bash**, which makes Linux the most compatible operating system.

If you're running a different OS, here are your options:

---

## 🪟 Windows Users (Recommended: WSL2 + Docker Desktop)

To follow along on Windows, you can replicate the same environment by:

1. Enabling **WSL2 (Windows Subsystem for Linux)**
  - Installing **Ubuntu** from the Microsoft Store  
  - This gives you a Linux shell capable of running Bash scripts*
2. Installing **Docker Desktop for Windows**
  - Make sure **“Use Docker with WSL2”** is enabled  
  - Docker Desktop will handle container runtime integration automatically
3. Running the Catalyst deployment script **inside Ubuntu/WSL2**
  - Place your `docker-compose.yml` and config files inside the Ubuntu filesystem  
  - Run your Bash script exactly as you would on a native Linux machine
4. Launch an Ubuntu/Linux Virtual Machine
  - You can follow along without issue

---

## 🍎 macOS Users

macOS users can follow along natively by:

- Installing **Docker Desktop for Mac**
- Running the Bash installer script directly in **Terminal**  
  *(macOS supports Bash and zsh natively)*

The multi-container Catalyst stack works **identically** on macOS.

---

## 🖥️ Other Linux Distributions

Any major Linux distribution (Ubuntu, Debian, Fedora, Kali, Arch, etc.) can run this project as long as:

- **Docker Engine** is installed  
- **Docker Compose** is available  
- The filesystem supports the file paths in your script

---

# Step 1: Setup

To begin this project, I installed the Docker Engine on my local machine, and ran the setup script to start the Catalyst application.

>Note: The following setup instructions are written for **Ubuntu** systems.
If you are using a different operating system, refer to the **About Operating Systems** section in Preliminary Information.

---

## 🔧 Installing Docker

To download Docker, open the terminal and run the commands below:
>Note: If you already have Docker installed, go to the **Executing Installation Script** section

### Update the package index
```bash
sudo apt-get update
```
>This command updated the package index

### Install required packages
```bash
sudo apt-get install -y ca-certificates curl gnupg lsb-release
```

### Add Docker’s official GPG key
```bash
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
```

### Add the Docker apt repository
```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

### Install Docker Engine + CLI + containerd
```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

### Allow running docker without sudo
```bash
sudo usermod -aG docker $USER
```
>Note: Create a new terminal session for this command to take effect

### Verfiy Successful Installation
```bash
docker --version
docker compose version
```

If you're successful, you should see something like this in the terminal

```bash
ubuntu@ip-172-31-71-103:~$ docker --version
Docker version 29.1.2, build 890dcca
ubuntu@ip-172-31-71-103:~$ docker compose version
Docker Compose version v5.0.0
ubuntu@ip-172-31-71-103:~$
```

---

## Executing Installation Script

Once you've installed Docker, go to the [Scripts](../Scripts) folder and download the `setup_catalyst.sh` in the directory that you want this project to live.
>Note: You're free to look over and change the script as you please to fit your needs.

### Grant Execute Permissions
```bash
chmod 700 <Your scripts name>
```
>This grants execute permissions to the owner of the script.

### Execute It
```bash
./setup_catalyst.sh
```
>Note: Answer yes(y) to prompts when asked.

If successful, you should begin to see output in your terminal showing:
- Secrets being generated
- Configuration files being created
- Docker containers being pulled
- Catalyst services starting successfully

[Picture](../report/images/Script%20Output.png)
---

## Accessing Catalyst

To access Catalyst, in your browser, paste the Catalyst URL that you got from the script.

```text
 https://catalyst.localhost
```
>Note: Your browser will warn that the site is “unsafe” because it uses self-signed certificates.
This is expected in a local lab environment, proceed anyway.

You should be met with the Catalyst home page telling you to login with OIDC. Click the button to be taken to the authentication page.

[Picture](../report/images/Catalyst%20Login%20Page.png)

---
### Login Credentials
Use the default credentials:
- **Username**: `admin`
- **Password**: `admin`

Click **Accept** on the following page.

If everything was done correctly, you should be met with the Catalyst dashboard.

[picture](../report/images/Catalyst%20Dashboard2.png)

---

## Extra

If you're having trouble authenticating, visit the [TroubleShooting](../Scripts/TroubleShooting.md) file for some help

---

# Step 2: Incident A SolarWindsIOC

In this steo, I create an incident ticket for the SolarWinds IoCs that were found in the Splunk project.

To do this, in Catalyst, click on `incidents` on the left-hand taskbar. Click `New Ticket` and fill in the information for the incident.

- **Name**: SolarWinds IOC Compromise
- **Description**: IP addresses found from the SolarWinds IOC threat feed
- **Severity**: High

Click save.

You should now be shown the incident ticket you just created.

![pictute](../report/images/Incident%20Ticket.png)

---



