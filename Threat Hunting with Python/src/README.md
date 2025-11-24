## 📂 src Directory

This directory contains all Python scripts used throughout the project to parse, filter, enrich, and investigate the CloudTrail dataset.  
It also includes `requirements.txt`, which lists the exact package versions needed to run the analysis within a virtual environment.

---

### 🔹 [enrich_s3_events.py](./enrich_s3_events.py)

This script loads the original CloudTrail dataset, extracts all S3-related activity, and flattens nested JSON structures to produce an investigation-ready dataset.

**Key functions include:**

- Filtering for S3 events (`ListBuckets`, `ListObjects`, `GetObject`)
- Normalizing nested fields like `userIdentity` and `requestParameters`
- Standardizing timestamps
- Exporting results as both JSONL and CSV

📁 **Outputs stored in:** `data/cleaned_data/`

---

### 🔹 [extended_search.py](./extended_search.py)

This script performs a pivot-based IoC search across the entire CloudTrail dataset using indicators extracted from the enrichment step.

It searches for:

- Compromised `principalId`
- Compromised `accessKeyId`
- Unique attacker `userAgent` string

For each indicator, the script generates a dedicated dataset and also produces a combined JSONL file with duplicates removed.

📁 **Outputs stored in:** `data/extended_search/`

---

### 🔹 [filter_s3_events.py](./filter_s3_Events.py)

This script filters the original dataset to isolate S3-only activity, then separates those events into two categories:

- **Management Events** (`ListBuckets`)
- **Data Events** (`ListObjects`, `GetObject`)

It exports:

- 3 JSONL files  
- 3 matching CSV files  
- A combined S3 event dataset

📁 **Outputs stored in:** `data/s3_events/`

---

### 🔹 [parse.py](./parse.py)

This script performs the initial parsing and exploration of the dataset.

It:

- Loads the original CloudTrail JSONL file into a DataFrame

It outputs:

- The first 5 records of the dataset  
- Results from `df.head()`, `df.info()`, and `df.columns.to_list()`

📁 **Outputs stored in:** `data/raw_data/`

---

### 🔹 [requirements.txt](./requirements.txt)

This file lists all Python packages and their specific versions used across the project.  
It is intended for creating a reproducible virtual environment using:

```bash
pip install -r requirements.txt
```