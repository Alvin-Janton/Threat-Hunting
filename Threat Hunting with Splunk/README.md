# Threat Hunting with Splunk: SolarWinds IOC Correlation & Network Analysis

## 📌 Overview
This project demonstrates a complete, SOC-style threat-hunting workflow using **Splunk Enterprise** and custom network proxy logs.  
By ingesting a simulated network dataset and correlating it against known malicious Indicators of Compromise (IoCs) from the **SolarWinds supply-chain attack**, I perform end-to-end detection, analysis, visualization, and reporting inside Splunk.

The goal of this project is to practice real-world investigative techniques using SIEM-based log analysis, lookup tables, IOC enrichment, and dashboard creation.

This is a training-oriented walkthrough designed to highlight methodology, Splunk proficiency, structured documentation, and analytical reasoning.

---

## 🎯 Objectives
In this project I demonstrate how to:

- Ingest CSV-based threat intelligence and network logs into Splunk  
- Verify field extraction and interpret Splunk event formatting  
- Build a **lookup table** to isolate IP-based threat indicators  
- Write SPL queries to correlate network events with SolarWinds malicious IPs  
- Identify impacted hosts, timestamps, and threat categories  
- Create a Splunk dashboard panel for continuous IOC monitoring  
- Produce a SOC-style **incident report** documenting all findings  

---

## 📁 Repository Structure

```graphql
project-root/
│
├── README.md                     # High-level project overview
│
├── data/                         # Raw intelligence & network log datasets
│   ├── NetworkProxyLog02.csv         # Simulated network proxy log
│   └── SolarWindsIOCs.csv            # SolarWinds IOC feed (domains, hashes, IPs)
│
├── Docs/
│   └── walkthrough.md            # Full step-by-step Splunk investigation with screenshots
│
├── report/
│   ├── incident_report.md        # SOC-style incident report based on IOC findings
│   └── images/                   # Visuals supporting the walkthrough & report
```
---

## 🧰 Tools & Technologies
- **Splunk Enterprise** (Free Trial)  
- **SPL (Search Processing Language)**  
- **CSV-based threat intelligence**  
- **IOC lookup tables**  
- **Network proxy logs**  
- **VirusTotal** (IP reputation analysis)

---

## 📘 Dataset Description

This project uses two primary CSV datasets:

### 1. **NetworkProxyLog02.csv**
A simulated network proxy log containing:

- Timestamps (`Date`, `Time`)
- Hostnames
- User agents
- Internal and external IP addresses

This log simulates real enterprise outbound web traffic.

### 2. **SolarWindsIOCs.csv**
A threat feed listing multiple IOC types:

- IP-based indicators  
- Malicious domains  
- File paths  
- SHA256 malware hashes  
- Descriptions of **SUNBURST**, **TEARDROP**, and related malware  

The project focuses on **IP-based IoCs**, which are extracted and converted into a lookup table.

---

## 🧭 Investigation Approach

This project follows a structured SIEM-based threat-hunting methodology:

### **1. Dataset Validation**
Inspect fields, timestamps, and extraction correctness.

### **2. Threat Intelligence Preparation**
Filter the IOC feed to IP indicators and convert them into a Splunk lookup table.

### **3. Correlation & Detection**
Use SPL lookup commands to identify network events contacting malicious SolarWinds infrastructure.

### **4. Analysis & Documentation**
Identify impacted hosts, trends, and behaviors from correlated results.

### **5. Dashboarding**
Build a Splunk dashboard panel to monitor for new matching events over time.

### **6. Incident Response Reporting**
Create a SOC-style incident report summarizing the findings.

---

## 📊 Key Outcomes (High-Level)

- Identified **three unique malicious SolarWinds IP addresses** contacted by internal hosts  
- Mapped all IoC matches to exact timestamps and hostnames  
- Demonstrated **Splunk lookup table creation** and IOC enrichment  
- Created a **Splunk dashboard** panel for continued monitoring  
- Produced a complete walkthrough documenting each phase  
- Wrote a detailed **SOC-style incident report** summarizing the findings  

---

## 📄 Full Documentation

- 📘 **Complete Walkthrough:** [walkthrough](./Docs/walkthrough.md) 
- 📘 **Incident Report:** [incident report](./report/ir_SolarWinds_Network_Compromise.md)

---
