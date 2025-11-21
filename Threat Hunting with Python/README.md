# Threat Hunting with Python: Investigating Potential Unintended S3 Access

## 📌 Overview
This project demonstrates my approach to SOC-style threat hunting using Python and AWS CloudTrail logs.  
Using **Pandas**, I analyze a raw JSON Lines CloudTrail dataset containing mixed AWS service activity, including evidence of potential S3 misconfiguration and unintended access.  
The goal of this project is to show how a structured threat-hunting playbook can guide filtering, parsing, and analysis to uncover meaningful indicators within a large dataset.  
This is a training-style walkthrough intended to highlight methodology, documentation, and analytical reasoning.

---

## 🎯 Objectives
In this project I showcase how to:
- Parse and clean raw CloudTrail JSON logs using Pandas  
- Isolate S3-related events from a mixed-service dataset  
- Apply a threat-hunting playbook (Unintended S3 Access)  
- Identify suspicious or misconfigured behaviors  
- Document an investigation clearly using visuals and step-by-step reasoning  

---

## 📁 Repository Structure
project-root/
│
├── README.md                  # Project overview (this file)
│
├── data/
│   ├── raw/                   # Original CloudTrail JSON Lines dataset
│   └── processed/             # Cleaned/filtered outputs (CSV, graphs, etc.)
│
├── Docs/
│   └── walkthrough.md         # Full detailed walkthrough with screenshots
│
├── report/
│   ├── findings.md            # SOC-style incident summary and conclusions
│   └── screenshots/           # Visuals referenced in documentation
│
└── src/
    ├── parse_json.py          # JSON loading and normalization
    ├── clean_cloudtrail.py    # Cleaning and preprocessing
    ├── extract_s3_events.py   # Filtering S3-related activity
    └── visualize.py           # Graphs and timeline visualizations

---

## 🧰 Tools & Technologies
- Python (pandas, json, matplotlib/seaborn)  
- Jupyter Notebook  
- AWS CloudTrail (JSON Lines format)  
- Threat Hunting Playbook: **Unintended S3 Access**  
- Git/GitHub  

---

## 📘 Dataset Description
- Raw AWS CloudTrail logs in JSON Lines format (1 event per line)  
- Mixed-service activity: EC2, IAM, S3, STS, and others  
- Contains nested, multi-field structures typical of CloudTrail  
- Investigation focuses on identifying **S3-related behavior** that may indicate unintended access or misconfiguration  

---

## 🧭 Investigation Approach
This project follows a training-oriented, structured approach:

- Using the playbook to define investigative questions  
- Filtering, normalizing, and analyzing log fields of interest  
- Correlating S3 access patterns with user identities, IP addresses, and timestamps  
- Using visuals to highlight patterns and potential indicators  
- Documenting findings clearly for both technical and non-technical audiences  

---

## 📊 Key Outcomes (High-Level)
- Identified patterns of S3 bucket access across mixed CloudTrail activity  
- Mapped S3 events to specific users, timestamps, and source IPs  
- Isolated relevant S3 operations (GetObject, ListBucket, etc.)  
- Applied cleaning and normalization techniques to parse JSON Lines logs  
- Demonstrated the value of playbooks in structuring cloud investigations  
- Produced a complete walkthrough with screenshots and code examples  

---

## 📄 Full Documentation
📘 **Full Walkthrough:** [Docs/walkthrough.md](./Docs/walkthrough.md)

