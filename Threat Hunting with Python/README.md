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
```graphql
project-root/
│
├── README.md                     # High-level project overview
│
├── data/
│   ├── ec2_proxy_s3_exfiltration/    # Original CloudTrail JSON Lines dataset (unmodified)
│   │   └── ec2_proxy_s3_exfiltration_2020-09-14011940.json
│   │
│   ├── raw_data/                     # Quick previews + structural summaries
│   │   ├── raw_preview.json          # First N raw events (pretty-printed)
│   │   └── df_preview.md             # df.head(), df.info(), df.columns overview
│   │
│   ├── s3_events/                    # Filtered S3-only subsets
│   │   ├── s3_all_events.jsonl
│   │   ├── s3_management_events.jsonl
│   │   └── s3_data_events.jsonl
│   │
│   ├── cleaned_data/                 # Cleaned/enriched S3 activity
│   │   ├── s3_enriched_events.jsonl  # Primary enriched dataset (JSONL)
│   │   └── s3_enriched_events.csv    # Legacy CSV export (kept for convenience)
│   │
│   └── exteneded_search/             # Extended IoC pivot searches (JSONL only)
│       ├── search_principalId.jsonl
│       ├── search_accessKeyId.jsonl
│       ├── search_userAgent.jsonl
│       └── extended_search_combined.jsonl
│
├── Docs/
│   ├── walkthrough.md                # Full analysis walkthrough with screenshots
│               
│
├── report/
│   ├── ir_data_exfiltration.md       # SOC-style incident report (IRP–DataAccess)
│   └── images/                       # Visuals referenced in the incident report
│
└── src/
    ├── parse.py                      # Dataset preview + structure export
    ├── filter_s3_events.py           # Filtering + categorizing S3 activity
    ├── enrich_s3_events.py           # Flattening/enriching S3 CloudTrail events
    └── extended_search.py            # Indicator pivoting across full dataset
```
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
📘 **Full Walkthrough:** [walkthrough.](./Docs/walkthrough.md)
📘 **Incident Report:** [Incident Report](./report/ir_Data_Exfiltration.md)

