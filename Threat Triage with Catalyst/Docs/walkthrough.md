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


