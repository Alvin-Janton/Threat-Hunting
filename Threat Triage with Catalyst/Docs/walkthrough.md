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

![Picture](../report/images/Script%20Output.png)
---

## Accessing Catalyst

To access Catalyst, in your browser, paste the Catalyst URL that you got from the script.

```text
 https://catalyst.localhost
```
>Note: Your browser will warn that the site is “unsafe” because it uses self-signed certificates.
This is expected in a local lab environment, proceed anyway.

You should be met with the Catalyst home page telling you to login with OIDC. Click the button to be taken to the authentication page.

![Picture](../report/images/Catalyst%20Login%20Page.png)

---
### Login Credentials
Use the default credentials:
- **Username**: `admin`
- **Password**: `admin`

Click **Accept** on the following page.

If everything was done correctly, you should be met with the Catalyst dashboard.

![picture](../report/images/Catalyst%20Dashboard2.png)

---

## Extra

If you're having trouble authenticating, visit the [TroubleShooting](../Scripts/TroubleShooting.md) file for some help

---

# Step 2: Incident A — SolarWinds IOC Investigation

In this step, I create an incident in Catalyst and document the malicious IP addresses identified during the **Threat Hunting with Splunk** project. These IoCs originated from the SolarWinds-associated threat feed and were matched against the proxy logs during the hunt.

---

## Creating the Incident

To begin:

1. In Catalyst, select **“Incidents”** from the left-hand sidebar.  
2. Click **“New Incident.”**  
3. Fill in the incident details:

   - **Name:** SolarWinds IOC Compromise  
   - **Description:** IP addresses identified from the SolarWinds IOC threat feed  
   - **Severity:** High  

4. Click **Save** to create the incident.

You should now see the incident overview page:

![picture](../report/images/Incident%20Ticket.png)

---

## Adding Artifacts (Observables)

On the right-hand side of the incident page, open the **Artifacts** panel.

For each suspicious IP address:

1. Click **“Create Artifact.”**  
2. Enter the IoC (e.g., the malicious IP address).  
3. Assign the following properties:

   - **Status:** Malicious  
   - **Kind:** IOC  
   - Use the button next to `hash.sha1` to automatically generate a fingerprint for the observable.

![picture](../report/images/Artifact%20Creation.png)

Repeat this process for each of the IP addresses associated with the SolarWinds IOC feed.

---

## Threat Triage & External Reputation Checks

To validate the severity of each IP, I performed external reputation checks using **VirusTotal** and **AbuseIPDB**.

### VirusTotal
- Paste the IP address into the VirusTotal search bar.  
- A high community score (typically **Greater than 4 or 5**) indicates that the IP is widely recognized as malicious.

![picutre](../report/images/VirusTotal%20Result.png)

### AbuseIPDB
- Search the same IP on AbuseIPDB to confirm its reputation and previous abuse reports.

![picutre](../report/images/AbuseIPDB%20Result.png)

Performing these reputation checks helps distinguish between:

- Truly malicious infrastructure  
- Compromised systems temporarily abused  
- Benign but suspicious-looking IoCs  

This reduces false positives and helps assess the real threat level.

---

## Documenting Findings & Closing the Incident

Once all IoCs are added and verified, add a short written summary to the incident describing:

- Where the IoCs originated (SolarWinds threat feed)  
- How they were matched (proxy log scans during Splunk hunt)  
- Their confirmed reputation from triage  
- Any relevant notes or patterns

Finally, **close the incident**.

![pciture](../report/images/Incident(A)%20Closed.png)

---

# Step 3: Incident B - S3 Data Exfiltration



