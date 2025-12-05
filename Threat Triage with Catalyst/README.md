# **Incident Recreation in Catalyst: SOC-Style Investigation Workflow**

## 📌 Overview

This project recreates two previously completed threat-hunting investigations inside **Security Brewery’s Catalyst**, a full-featured, open-source incident response platform.

Using the full IR-capable, Docker-based version of Catalyst, I reproduced both investigations as structured incidents, added observables, performed enrichment, documented findings, and formally closed each case.

This project focuses on **incident documentation, artifact management, enrichment workflows, and SOC-style reporting**, rather than original log parsing or detection engineering.  
All investigative findings originate from earlier threat-hunting projects:

- **Threat Hunting with Splunk – SolarWinds IOC Correlation**
- **Threat Hunting with Python – S3 Data Exfiltration**

Catalyst is used to translate those results into incident tickets that mirror a real IR team’s workflow.

---

## 🎯 Objectives

In this project, I demonstrate how to:

- Deploy the legacy, feature-rich Catalyst IR platform using a custom multi-container script  
- Create structured incidents based on previously analyzed threat-hunting data  
- Add, classify, and manage observables (artifacts)  
- Apply external enrichment sources (VirusTotal, AbuseIPDB) where appropriate  
- Document malicious and compromised cloud identities, credentials, and assets  
- Write clear investigative notes and close incidents  
- Mirror real-world SOC and IR processes inside a ticketing system  

---

## 📁 Repository Structure

```graphql
project-root/
│
├── README.md                      # High-level project overview (this file)
│
├── Scripts/
│   ├── setup_catalyst.sh          # Full Catalyst IR stack deployment script
│   ├── troubleshooting.md         # Troubleshooting guide for service access issues
│
├── Docs/
│   └── walkthrough.md             # Step-by-step Catalyst investigation recreation
│
├── report/
│   ├── README.md.md               # Short file linking to the previous project's
│   └── images/                    # Screenshots used throughout the walkthrough
│
```

---

## 🧰 Tools & Technologies

- **Catalyst** (Docker-based legacy IR platform)
- **Docker & Docker Compose**
- **Authelia + Nginx reverse proxy** (authentication and routing)
- **Ubuntu EC2 instance** (remote deployment target)
- **VirusTotal / AbuseIPDB** (external enrichment sources)
- **Git/GitHub**

---

## 🧭 Investigation Approach

This project focuses on recreating prior threat-hunting results inside Catalyst, **not** re-processing or re-parsing log data.  
Instead, Catalyst is used as a structured IR system for documenting, enriching, and closing incidents.

### **1. Deployment**

Using a custom Bash script, the full Catalyst IR stack was deployed on an Ubuntu EC2 instance.

The script:

- Generates required directories, secrets, and certificates  
- Builds Authelia and Docker configuration files  
- Configures an Nginx reverse proxy  
- Launches all Catalyst containers  
- Sets up DNS-style hostnames for local access  

---

### **2. Incident A — SolarWinds IOC Compromise**

Imported the malicious IP addresses discovered during the Splunk threat-hunting project.

Actions performed:

- Added IP-based observables  
- Marked them as **Malicious**  
- Enriched via VirusTotal and AbuseIPDB  
- Documented notes and closed the incident  

---

### **3. Incident B — S3 Data Exfiltration**

Recreated findings from the CloudTrail-based Python investigation.

Actions performed:

- Added malicious User-Agent and attacker IP  
- Documented compromised assets:
  - Principal ID  
  - Temporary access key  
  - S3 object path  
- Classified observables appropriately  
- Summarized attacker behavior and closed the incident  

---

### **4. Documentation & Closure**

Each incident includes:

- Clear artifact classification  
- Investigative notes explaining context and relevance  
- Screenshots  
- A structured, IR-style summary  
- A unified conclusion covering both incidents  

---

## 📊 Key Outcomes (High-Level)

- Recreated two independent investigations inside Catalyst  
- Demonstrated the difference between **malicious observables** and **compromised-but-legitimate assets**  
- Used Catalyst’s artifact system for clear IoC structuring and reusability  
- Applied external threat intelligence validation where relevant  
- Produced a complete walkthrough demonstrating SOC workflow replication  
- Validated Catalyst as a powerful platform for IR case documentation  

---

## 📄 Full Documentation

📘 **Complete Walkthrough:** [walkthrough](../Threat%20Triage%20with%20Catalyst/Docs/walkthrough.md)
