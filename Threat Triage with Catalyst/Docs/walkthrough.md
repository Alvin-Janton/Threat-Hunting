# 📝 Preliminary Information

Before starting this project, I installed Catalyst on my local machine and created an administrator account.  
This allows me to generate incidents, add observables, run enrichments, and document the full investigation workflow.

---

## 🌐 Environment

This project is conducted inside **Catalyst**, a free and open-source incident response platform designed to support SOC workflows.  
Catalyst enables analysts to:

- Create and manage incidents  
- Attach observables and run enrichments  
- Build evidence-based timelines  
- Document analysis and export reports  

All steps of the investigation are performed within a centralized interface.

---

## 📂 Data Sources

All indicators and investigative details used in this project come from two prior threat-hunting investigations:

- **Threat Hunting with Splunk** (SolarWinds IOC Correlation)  
- **Threat Hunting with Python** (AWS CloudTrail Exfiltration Case)

These projects supplied the IoCs and artifacts used to build each Catalyst incident, including:

- Malicious IP addresses  
- Principal ID / temporary access key metadata  
- Attacker user-agent strings  
- S3 object paths  
- Additional identifiers supporting correlation  

---

## 🧭 If You Want to Follow Along

If you're new to Catalyst or incident-response tooling, the following documentation will help with installation and basic features:

### 📘 Catalyst Handbook  
Covers installation, configuration, incident creation, observables, and enrichments.  
- ➡️ https://catalyst.security-brewery.com/docs/category/catalyst-handbook

### 💻 Catalyst GitHub Repository  
Source code, releases, templates, and examples.  
- ➡️ https://github.com/SecurityBrewery/catalyst

---

# Step 1: Setup

To begin this project, I installed Catalyst on my local machine and created an administrator user.  
This allows me to create incidents, add observables, run enrichments, and document investigations within the platform.

---

## 🔧 Installing Catalyst

Download Catalyst from the official GitHub releases page:

➡️ https://github.com/SecurityBrewery/catalyst/releases

Select the ZIP archive for your operating system.

![pciture](../report/images/Catalyst%20Zip%20Folders.png)

---

Select the ZIP archive for your operating system.

After downloading, unzip the folder and navigate into the directory that contains the Catalyst executable.

Your working directory should look similar to the following:

```bash
C:\Users\alvin\downloads\catalyst_Windows_x86_64

Mode                 LastWriteTime         Length Name
----                 -------------         ------ ----
d-----        11/29/2025  11:39 AM                catalyst_data
-a----        11/29/2025  11:22 AM       19854848 catalyst.exe
-a----        11/29/2025  11:22 AM          34336 LICENSE
-a----        11/29/2025  11:22 AM           3099 README.md
```

> **Note:** The binary name may vary depending on your OS (e.g., `.exe` for Windows, no extension for Linux/Mac).

---

## Creating an Admin

To create an administrator user in Catalyst, run the appropriate command for your OS.

```bash
.\catalyst.exe admin create ExampleUser@gmail.com password123 # Windows

./catalyst admin create ExampleUser@gmail.com password123     # Linux/Mac
```
>Note: Replace the example username and password with real credentials, and make sure you run the command from the Catalyst directory  
(unless you’ve added Catalyst to your system PATH).

If successful, you will be able to log in after launching Catalyst.

---

## 🚀 Launching Catalyst

Start Catalyst using the `serve` command:

```bash
.\catalyst.exe serve # Windows
./catalyst serve     #Linux/Mac
```

---
You should see something similar in your terminal:

```bash
PS C:\Users\alvin\downloads\catalyst_Windows_x86_64> .\catalyst serve
2025/11/29 14:40:08 INFO Connecting to database path=catalyst_data\data.db
2025/11/29 14:40:08 INFO Current database version version=5
2025/11/29 14:40:08 INFO No migrations to apply
2025/11/29 14:40:08 INFO Starting Catalyst server address=:8090
```
>Note: To stop Catalyst, just enter ctrl+C
---

Access Catalyst in your browser at:

```arduino
http://localhost:8090
```

---

You should now see the login screen.  
![picture](../report/images/Catalyst%20Login.png)

---

Enter your admin credentials.  
If authentication succeeds, you will be taken to the Catalyst dashboard.
![picture](../report/images/Catalyst%20Dashboard.png)

---

Now, we can begin creating tickets and investigations.

---

## Extra

If you want to run Catalyst in the background without cluttering your terminal, use the appropriate commands for your OS.

### Start Catalyst Silently in Powershell (Windows)
```bash
Start-Process powershell 
  -WindowStyle Hidden 
  -WorkingDirectory "Path to Catalyst"
  -ArgumentList 'catalyst serve'
```

### Stop Catalyst Silently in Powershell (Windows)
```bash
Get-Process catalyst -ErrorAction SilentlyContinue | Stop-Process
```

### Start Catalyst Silently in Bash (Linux/Mac)
```bash
nohup bash -c "cd /path/to/catalyst && ./catalyst serve" > catalyst.log 2>&1 &
```

### Stop Catalyst Silently in Bash (Linux/Mac)
```bash
pkill catalyst
```

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



