# 🛈 Preliminary Information

Before beginning this project, I needed to install and configure Splunk on my device so I could ingest log data and perform threat-hunting queries.

---

## 🌐 Environment

For this investigation, I am using **Splunk Enterprise (Trial Mode)** as my SIEM platform.  
This provides all features needed for data ingestion, searching, and dashboard creation.

---

## 📂 Dataset Selection

This project uses two CSV files that will be ingested into Splunk for analysis:

- **NetworkProxyLog02.csv** — Simulated network proxy logs representing outbound connections made by hosts across an enterprise network.
- **SolarWindsIOCs.csv** — A collection of known malicious indicators associated with the SolarWinds supply-chain compromise, including IP-based command-and-control infrastructure.

Both files are available in the project’s **[data](../data/)** folder.

> **Note:** These datasets are simulated and provided for educational purposes.  
> They do not represent real organizational traffic or live threat intelligence.

---

## 🧭 If You Want to Follow Along

If you're new to Splunk or threat hunting, these resources may help you get started:

### 📺 Installing Splunk & Basic Usage (Video Tutorial)  
➡️ https://youtu.be/3CiRs6WaWaU?si=iHzCo0nbF7rU0T9S

### 📘 Splunk Fundamentals Courses  
➡️ https://www.splunk.com/en_us/training/splunk-fundamentals.html

### 📄 Splunk Cheat Sheet  
➡️ https://github.com/vaquarkhan/splunk-cheat-sheet

### 📗 Splunk Quick Reference Guide  
➡️ https://www.splunk.com/en_us/resources/splunk-quick-reference-guide.html

---


