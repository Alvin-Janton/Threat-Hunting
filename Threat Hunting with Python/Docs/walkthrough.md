# Preliminary Information
---

Before beginning this project, I needed to set up my Python environment, install the required dependencies, choose an incident-response playbook, and identify the dataset I would use for the investigation.

### ⚙️ Environment & Tools
- For this project, I am using **Python 3.13** in **VS Code**.
- My dependencies include: **pandas**, **ipykernel**, **matplotlib**, **jupyter**, and **seaborn**.  
  You can view exact versions in my [`requirements.txt`](../src/requirements.txt) file.

### 📘 Playbook Selection
I selected the **IRP-DataAccess** playbook from the AWS Incident Response Playbooks collection.  
You can view it here:  
➡️ https://github.com/aws-samples/aws-incident-response-playbooks/blob/master/playbooks/IRP-DataAccess.md

This playbook focuses on responding to suspicious or unintended access to AWS data stores such as S3 , which aligns perfectly with the dataset being analyzed.

### 📂 Dataset Selection
For this investigation, I am using the **AWS Cloud Bank Breach S3 dataset**, which simulates a real-world attack where an adversary obtains exposed credentials from a misconfigured EC2 instance and uses them to exfiltrate data from an S3 bucket.

Dataset source:  
➡️ https://securitydatasets.com/notebooks/atomic/aws/initial_access/SDAWS-200914011940.html

This dataset contains CloudTrail logs in **JSON Lines** format, including EC2, STS, IAM, and S3 events.  
It is ideal for demonstrating a training-style threat hunting walkthrough.

---

### 🧭 If You Want to Follow Along
If you are new to Python or threat hunting, the following beginner-friendly resources may help:

- Installing VS Code and Python  
  ➡️ https://youtu.be/D2cwvpJSBX4?si=xFHLBld8JlNn7mXr

- Creating a Python virtual environment  
  ➡️ https://youtu.be/Y21OR1OPC9A?si=mvE0GEKUJtT8ZUg8

- Pandas syntax cheatsheet  
  ➡️ https://www.dataquest.io/cheat-sheet/pandas-cheat-sheet/

---

# Step 1: Setup
To start this project, I first created a virtual environment in Python to install all of the necessary dependencies.

> Note: A virtual environment is an isolated folder that works as a local package manager, storing all dependencies required for your project.

To create a virtual environment in python, run:
```bash
python -m venv venv  # Windows
python3 -m venv venv # Linux/Mac
```
> Note: The final argument (venv) is the folder name. You can name it anything you want.

After this, you should see a new folder in your directory with the name you selected.
![Picture](../report/images/VENV%20Setup.png)

### Activate Environment
Once you've created your virtual environment, you want to activate it. To do this, run

```bash
venv\Scripts\Activate.ps1 # Windows
source venv/bin/activate  # Linux/Mac
```
> Note: Replace `venv` with the name of your virtual environment folder

If successful, you will see the environment name appear at the beginning of your terminal path.

![Picture](../report/images/Activate%20VENV.png)

> Note: To exit a virtual environment, just enter the command `deactivate` in the terminal

### Install Dependencies
Next, you want to install all of the dependencies needed for this project. To do that, run:

```bash
pip install -r requirements.txt
```
> Note: This command reads the file and installs each listed dependency.
To install a single dependency, use: `pip install dependency-name`.

To verify that you were successful, run the command below to view your dependencies :

```bash
pip list
```
> Note: You may see more packages installed than those listed in requirements.txt.
This is normal, libraries often depend on other libraries. You should keep these extra dependencies.

![Picture](../report/images/Installing%20Dependencies.png)
> Note: If you want to create a requirements.txt file run the command `pip freeze > requirements.txt` This will list all of your dependencies and their versions that you have installed into a portable file.

### Configure Your IDE
VS Code may still be using your system Python. To change this:

- In VS Code, go to the bottom right corner where your python version is listed. It shoud look something like `Python 3.xx`. Click this, it should take you to a interpreter selection. Enter the path to your virtual environment's python.exe file. It should look something like this `C:\Users\alvin\example\venv\scripts\python.exe`

> Note: If you don't do this, you'll likely get errors stating that the import cannot be found.

That completes the initial setup.
---

# Step 2: Dataset Exploration

With the environment configured, the next step was to explore the CloudTrail dataset and understand its structure. Because CloudTrail logs are stored in JSON Lines format (one JSON object per line), the file can look overwhelming when viewed as plain text. To make the investigation easier, I wrote a small script that:

1. Previews the first few raw events  
2. Loads the entire dataset into a pandas DataFrame  
3. Exports key information (head, schema, column names) into a Markdown file for clean viewing

These steps form the foundation for the rest of the analysis.

---

##  2.1 Imports and Path

To support this exploration, I imported a few essential Python libraries. The `json` module allows me to load each event from the JSON Lines file, while `pandas` is used to convert the entire dataset into a structured DataFrame for analysis. I also used `Path` from `pathlib` to handle file paths in a portable and consistent way, and `StringIO` to capture the output of `df.info()` so it could be exported cleanly into a Markdown summary file. These imports provide everything needed to inspect the dataset before moving into deeper analysis.

```python
import json
import pandas as pd
from pathlib import Path
from io import StringIO
```
---

Instead of hard-coding long absolute paths, I structured my project so all datasets and preview files live inside a dedicated `data/` directory. I used Python’s `Path` object to build these paths dynamically, which ensures the script remains portable across machines and works even if the project folder is moved. This also keeps all data-related artifacts organized in a single location, making the investigation easier to follow and reproduce.

```python
# Base paths (relative to this script)
BASE_DIR = Path(__file__).resolve().parents[1]   # project root (…/Threat hunting with python)
DATA_DIR = BASE_DIR / "data"

LOG_FILE = DATA_DIR / "ec2_proxy_s3_exfiltration" / "ec2_proxy_s3_exfiltration_2020-09-14011940.json"
RAW_LOGS_PREVIEW = DATA_DIR / "raw_preview.json"
DATAFRAME_PREVIEW = DATA_DIR / "df_preview.md"
```

## 🔍 2.2 Previewing Raw JSON Events

Before converting anything into pandas, I wanted to get a sense of what a single CloudTrail event looks like. Each event contains nested fields such as `userIdentity`, `eventSource`, `eventName`, `requestParameters`, and timestamps.  

Instead of printing the logs directly to the terminal, which becomes unreadable due to their length. I wrote two small helper function that extracts the first few events and writes them to a separate JSON file. This keeps things clean and allows me to reference the preview later in the project.

```python
def preview_raw_events(file_path, num_lines=5):
    """Reads the first N lines of a CloudTrail JSON Lines file."""
    events = []
    with open(file_path, "r", encoding="utf-8") as f:
        for _ in range(num_lines):
            line = f.readline()
            if not line:
                break
            events.append(json.loads(line))
    return events
```

```python
def save_preview_to_json(events, output_path):
    """Save pretty-printed raw events to a JSON file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as outfile:
        for idx, event in enumerate(events, start=1):
            outfile.write(f"--- Event {idx} ---\n")
            outfile.write(json.dumps(event, indent=2))
            outfile.write("\n\n")
```

Here's a snippet of what one of the event lines looks like the preview file

```json
--- Event 1 ---
{
  "requestParameters": {
    "DescribeInstanceTypesRequest": {
      "NextToken": "AAIAAUCZLcGdOTmfTz2Vwy7qCVgVq6KNMDDo2s_UFVQdUl8JzmoaM3geYg-eTVO56npOwVkgRcbnccOAIh5xaIntUaFwx3Yzg5z0gJcGwKSvIHr7PoKDSMugzTo27wztP16CU4jRhTPQdzL5kAyA8MMWqgrYKoT5J0xc",
      "MaxResults": 100
    }
  },
  "userAgent": "console.ec2.amazonaws.com",
  "awsRegion": "us-east-1",
  "eventType": "AwsApiCall",
  "@version": "1",
  "userIdentity": {
    "arn": "arn:aws:iam::123456789123:user/pedro",
    "type": "IAMUser",
    "userName": "pedro",
    "sessionContext": {
      "webIdFederationData": {},
      "sessionIssuer": {},
      "attributes": {
        "mfaAuthenticated": "true",
        "creationDate": "2020-09-13T17:16:47Z"
      }
    },
    "accountId": "123456789123",
    "principalId": "AIDAICAK2CN5MGHIIDIHA",
    "accessKeyId": "ASIA5FLZVX4OI4ZDQJOL"
  },
  "recipientAccountId": "123456789123",
  "responseElements": null,
  "eventName": "DescribeInstanceTypes",
  "sourceIPAddress": "1.2.3.4",
  "eventSource": "ec2.amazonaws.com",
  "requestID": "2db6a7b5-876c-4995-8258-e6f09d9ef934",
  "@timestamp": "2020-09-14T00:44:23.000Z",
  "eventID": "fd4f1042-c7f6-4107-a6ee-d841d92596e7",
  "eventVersion": "1.05"
}
```

This preview confirmed that the dataset contains mixed AWS activity (IAM events, EC2 events, and S3 events), which aligns with the scenario of attackers using compromised EC2 credentials.

---

## 📊 2.3 Loading the Dataset Into a DataFrame

Next, I loaded the full dataset into a pandas DataFrame. Pandas automatically parses each JSON object as a row and handles nested structures as Python dictionaries.

```python
def load_as_dataframe(file_path):
    """Loads the entire JSON Lines dataset as a pandas DataFrame."""
    return pd.read_json(file_path, lines=True)
```  
---

## 📝 2.4 Generating a Dataset Overview File

To organize the results, I built a helper function that writes all the structural information into a single Markdown file inside the `data/` folder. This file acts as a quick reference for the rest of the investigation.

```python
def generate_markdown_summary(df, output_path):
    """Exports df.head(), df.info(), and df.columns into a markdown file."""
    output_path.parent.mkdir(parents=True, exist_ok=True)

    # Capture df.info() output
    buffer = StringIO()
    df.info(buf=buffer)
    info_text = buffer.getvalue()

    md = []
    md.append("# Dataset Overview\n")
    md.append("---\n\n")

    md.append("## 🔹 DataFrame Head (first 5 rows)\n")
    md.append("```\n")
    md.append(str(df.head()))
    md.append("\n```\n\n")

    md.append("## 🔹 DataFrame Info\n")
    md.append("```\n")
    md.append(info_text)
    md.append("```\n\n")

    md.append("## 🔹 Columns\n")
    md.append("```\n")
    md.append(str(df.columns.tolist()))
    md.append("\n```\n\n")

    with open(output_path, "w", encoding="utf-8") as f:
        f.writelines(md)
```

Using this helper function I exported three important data views:

- `df.head()` , first 5 rows  
- `df.info()` , dataset size, column types, null counts  
- `df.columns` , the list of available fields


The resulting file includes:
- A preview of the data  
- The full schema  
- All column names in the dataset  

Here's a snippet showing the output of `df.info()`

```
<class 'pandas.core.frame.DataFrame'>
RangeIndex: 103 entries, 0 to 102
Data columns (total 22 columns):
 #   Column               Non-Null Count  Dtype  
---  ------               --------------  -----  
 0   requestParameters    98 non-null     object 
 1   userAgent            103 non-null    object 
 2   awsRegion            103 non-null    object 
 3   eventType            103 non-null    object 
 4   @version             103 non-null    int64  
 5   userIdentity         103 non-null    object 
 6   recipientAccountId   103 non-null    int64  
 7   responseElements     5 non-null      object 
 8   eventName            103 non-null    object 
 9   sourceIPAddress      103 non-null    object 
 10  eventSource          103 non-null    object 
 11  requestID            103 non-null    object 
 12  @timestamp           103 non-null    object 
 13  eventID              103 non-null    object 
 14  eventVersion         103 non-null    float64
 15  apiVersion           3 non-null      object 
 16  readOnly             13 non-null     float64
 17  sharedEventID        5 non-null      object 
 18  resources            14 non-null     object 
 19  eventCategory        9 non-null      object 
 20  additionalEventData  11 non-null     object 
 21  managementEvent      9 non-null      float64
dtypes: float64(3), int64(2), object(17)
memory usage: 17.8+ KB
```

If you want to see the full file for both the JSON and dataframe you can view them in the [data](../data/) Folder.

This provides a clean, readable overview of the log format and helps identify which fields are relevant for S3 threat analysis.

---

## ✅ Summary of Findings from Dataset Exploration

From this initial exploration, I learned that:

- The dataset contains CloudTrail events from several AWS services (EC2, IAM, S3, STS).  
- Many fields are nested, meaning I will need to flatten or normalize certain columns in later steps.  
- The dataset includes multiple S3-related event types, which is critical for analyzing unintended S3 access.  
- Structuring the preview in JSON and Markdown format makes the investigation easier and cleaner.

With the dataset now understood at a high level, the next step is to begin isolating S3 activity and applying the threat-hunting playbook.

--- 
# Step 3: Filtering for S3-Related Activity

Now that I understand the overall structure of the dataset, the next step is to narrow the focus to the events that matter most for this investigation: activity involving Amazon S3. The original CloudTrail file contains a mix of EC2, IAM, STS, and S3 events, but the playbook I’m following (IRP–DataAccess) is specifically concerned with unauthorized or unintended data access. That means S3-related events are the most relevant for identifying potential exfiltration behavior.

Rather than cleaning and transforming every event in the dataset, I first filter down to only the CloudTrail entries where `eventSource` corresponds to S3. From there, I separate S3 activity into two high-level categories:

- **Management events** – configuration-style actions (for example, listing buckets or modifying bucket policies)
- **Data events** – direct access to objects and data (for example, listing objects or reading objects from a bucket)

This separation mirrors how AWS itself classifies S3 events and aligns well with the incident-response playbook. Management events help reveal how an attacker discovers or sets up access to a bucket, while data events show how they actually interact with and exfiltrate contents. The goal of this step is to create smaller, focused DataFrames for S3 management and S3 data access activity that I can analyze more deeply in later steps.

## Step 3.1 Filtering S3 Events

To begin this step, I created a new Python script named `filter_s3_events.py`. I copied over the same imports and project-path definitions used in the previous file so both scripts share a consistent structure. I also reused the `load_as_dataframe()` method to load the full CloudTrail dataset into a pandas DataFrame.

Next, I wrote a function that filters the DataFrame to include only the rows where the `eventSource` equals `"s3.amazonaws.com"`.

```python
def filter_s3_events(df: pd.DataFrame) -> pd.DataFrame:
    """
    Returns only the rows where eventSource corresponds to S3.
    """
    s3_df = df[df["eventSource"] == "s3.amazonaws.com"].copy()
    return s3_df
```

Finally, in the main method I to print the number of S3 related events that exist in the dataset, as well as a list of the different event sources and how many times they show up.

```python
if __name__ == "__main__":
    print("Loading full CloudTrail dataset...")
    df = load_as_dataframe(LOG_FILE)
    print(f"   Total events: {len(df)}")

    print("\nFiltering for S3-related events (eventSource == 's3.amazonaws.com')...")
    s3_df = filter_s3_events(df)
    print(f"   S3 events: {len(s3_df)}")

    print("\nUnique S3 event names:")
    print(s3_df["eventName"].value_counts())
```

The output clearly shows a sequence of S3 actions consistent with bucket enumeration and object access:

```text
Loading full CloudTrail dataset...
  Total events: 103

Filtering for S3-related events (eventSource == 's3.amazonaws.com')...
  S3 events: 11

Unique S3 event names:
eventName
ListObjects    7
GetObject      2
ListBuckets    2
Name: count, dtype: int64
```

This gives me a strong initial indication that the attacker enumerated buckets, enumerated objects, and then downloaded objects, behavior fully consistent with S3 exfiltration.

## Step 3.2 Event Classification
In this step, I classify the S3 events into two separate DataFrames: one for `management events` and one for `data-access events`. Management events deal with high-level resource enumeration, while data-access events represent direct interaction with bucket contents. After classifying the events, I export each category to a CSV file for further analysis.

### Creating Files and Variables
I first defined the paths for the CSV files that will store the results:

```python
S3_ALL = DATA_DIR / "s3_all_events.csv"
S3_MANAGEMENT = DATA_DIR / "s3_management_events.csv"
S3_DATA = DATA_DIR / "s3_data_events.csv"
```

###
Next, I created two sets containing the S3 `eventName` values that belong to each category:

```python
# Define which S3 operations belong to which category
S3_MANAGEMENT_EVENTS = {
    "ListBuckets"
}

S3_DATA_EVENTS = {
    "ListObjects",
    "GetObject"
}
```

### Splitting S3 Categories
Then, I wrote a function that separates the S3 DataFrame into two subsets: one for management events and one for data-access events.

```python
def split_s3_categories(s3_df: pd.DataFrame):
    """
    Splits S3 events into management vs data-access DataFrames.
    """
    management_df = s3_df[s3_df["eventName"].isin(S3_MANAGEMENT_EVENTS)].copy()
    data_df = s3_df[s3_df["eventName"].isin(S3_DATA_EVENTS)].copy()

    return management_df, data_df
```
---

### Exploring Results

Finally, in the main block of the script, I used this classification function, printed the counts for each category, and exported all three DataFrames to CSV files inside the data/ directory:

```python
if __name__ == "__main__":

    df = load_as_dataframe(LOG_FILE)

    s3_df = filter_s3_events(df)

    print("\n📁 Splitting S3 events into categories...")
    management_df, data_df = split_s3_categories(s3_df)

    print(f"   Management events: {len(management_df)}")
    print(f"   Data-access events: {len(data_df)}")

    # Save results
    management_df.to_csv(S3_MANAGEMENT, index=False)
    data_df.to_csv(S3_DATA, index=False)
    s3_df.to_csv(S3_ALL, index=False)

    print("\n💾 Saved filtered files to /data/:")
    print(f"   - All S3 events:       {S3_ALL.name}")
    print(f"   - Management events:   {S3_MANAGEMENT.name}")
    print(f"   - Data-access events:  {S3_DATA.name}")
```
This step produces clean, focused datasets that isolate the attacker’s S3 behavior and prepare the groundwork for deeper analysis in the next phase.
---

# Step 4: Cleaning and Enriching S3 Events

With S3 activity filtered and categorized, the next step is to transform the raw CloudTrail entries into a format that is easier to analyze. CloudTrail logs are deeply nested JSON objects, and while they contain everything required for an investigation, their structure can make analysis slow and unintuitive.  

To align the dataset with the **IRP–DataAccess** playbook, this enrichment step extracts the most relevant fields, flattens nested structures, and standardizes timestamps for easier correlation.

The goal is to produce a clean, investigation-ready dataset showing **who accessed what, from where, and when**.

---

## 4.1 Why Enrichment Matters

The original CloudTrail event structure includes:

- Deeply nested objects (`userIdentity`, `requestParameters`, etc.)
- Hard-to-parse timestamps (`@timestamp`)
- Additional metadata not relevant to S3 access analysis

To perform threat hunting effectively, only a handful of key fields are needed. The enrichment process pulls out these important attributes and flattens them into a simple row-based structure that is easy to filter, sort, and follow chronologically.

In this step, I extract the following fields from each S3 event:

- **timestamp** (converted into a readable format)
- **eventName** (`ListObjects`, `GetObject`, etc.)
- **bucketName**
- **objectKey** (if present)
- **sourceIPAddress**
- **awsRegion**
- **userAgent** (useful for identifying attacker tooling)
- **IAM identity attributes** (`principalId`, `accessKeyId`, `userType`, etc.)

This produces a clean table representing each S3 action clearly.

---

## 4.2 Creating the Enrichment Script

I created a new Python file named `enrich_s3_events.py`.
At the top of the file, I imported the same libraries used in earlier steps and reused the same paths and loading functions.

I then wrote a helper function that safely handles nested JSON fields.
Some CloudTrail fields may appear either as dictionaries or JSON-encoded strings, depending on the event, so this function normalizes everything into a Python dictionary.

```python
def ensure_dict(value):
    """
    Ensures the value is a dictionary.
    If it's a JSON string, tries to json.loads() it.
    If it's already a dict or is null/NaN, returns it as-is or {}.
    """
    if isinstance(value, dict):
        return value
    if pd.isna(value):
        return {}
    if isinstance(value, str):
        value = value.strip()
        if not value:
            return {}
        try:
            return json.loads(value)
        except json.JSONDecodeError:
            return {}
    return {}
```

---

## 4.3 Flattening Each S3 Event

Next, I created a function to flatten a single S3 event.
This function extracts the essential fields for the investigation and returns them in a simple dictionary structure.

- `@timestamp`
- `eventName`
- `bucketName`
- `objectKey`
- `sourceIPAddress`
- `awsregion`
- IAM principal details (`userName`, `type`, `principalId`, `accessKeyId`)
- `userAgent` string (revealing attacker tools/OS)

Flattening the events not only simplifies the dataset but also makes it easier to spot evidence of reconnaissance and exfiltration.

```python
def flatten_s3_event(row: pd.Series) -> dict:
    """
    Flattens a single S3 CloudTrail event into a simpler dict with
    only the fields needed for investigation.
    """
    user_identity = ensure_dict(row.get("userIdentity"))
    req_params = ensure_dict(row.get("requestParameters"))

    # Basic top-level fields
    event_time = row.get("@timestamp")
    event_name = row.get("eventName")
    source_ip = row.get("sourceIPAddress")
    region = row.get("awsRegion")
    user_agent = row.get("userAgent")

    # User identity fields
    user_type = user_identity.get("type")
    user_name = user_identity.get("userName")
    principal_id = user_identity.get("principalId")
    access_key_id = user_identity.get("accessKeyId")

    # Request parameters: bucket + object key
    bucket_name = req_params.get("bucketName")
    object_key = req_params.get("key") or req_params.get("objectKey")

    return {
        "timestamp": event_time,
        "eventName": event_name,
        "bucketName": bucket_name,
        "objectKey": object_key,
        "sourceIPAddress": source_ip,
        "awsRegion": region,
        "userType": user_type,
        "userName": user_name,
        "principalId": principal_id,
        "accessKeyId": access_key_id,
        "userAgent": user_agent,
    }
```

This produces a standardized structure suitable for both CSV and JSONL output.

---

## 4.4 Saving the Enriched Dataset

After flattening each event, I converted the list of dictionaries into a pandas DataFrame.
This DataFrame is then exported into two formats:

- **CSV** — readable and sortable for manual inspection
- **JSON Lines (JSONL)** — ideal for investigative and automation workflows

```python
if __name__ == "__main__":
    print("Loading full CloudTrail dataset...")
    df = load_full_dataset(LOG_FILE)
    print(f"   Total events: {len(df)}")

    print("\nFiltering for S3-related events...")
    s3_df = filter_s3_events(df)
    print(f"   S3 events: {len(s3_df)}")

    print("\nFlattening S3 events into enriched rows...")
    enriched_rows = [flatten_s3_event(row) for _, row in s3_df.iterrows()]
    enriched_df = pd.DataFrame(enriched_rows)

    # Convert eventTime to datetime if possible
    if "timestamp" in enriched_df.columns:
        enriched_df["timestamp"] = pd.to_datetime(enriched_df["timestamp"], errors="coerce")

    # Save to CSV
    S3_ENRICHED.parent.mkdir(parents=True, exist_ok=True)
    enriched_df.to_csv(S3_ENRICHED, index=False)
    enriched_df.to_json(S3_ENRICHED_JSON, orient="records", lines=True, date_format="iso")

    print(f"\nSaved enriched S3 events to: {S3_ENRICHED}")
    print(f"Saved enriched JSON to: {S3_ENRICHED_JSON}")
    print("   Columns included:")
    print(list(enriched_df.columns))
```

Both output files are written to the `/data/` directory:

- `s3_enriched_events.csv`
- `s3_enriched_events.json`

---

## 4.5 What the Enriched Logs Reveal

Even a brief review of the enriched dataset shows a clear pattern of unauthorized activity:

- Multiple `ListObjects` calls against the same bucket
- A final `GetObject` retrieving the file **ring.txt**
- All actions coming from the same external IP address
- Actions performed using an **AssumedRole** associated with an EC2 instance
- `userAgent` indicates the attacker used AWS CLI from **macOS** outside AWS

A shortened example of an enriched record:

```json
{"timestamp":"2020-09-14T01:01:04.000Z","eventName":"ListObjects","bucketName":"mordors3stack-s3bucket-llp2yingx64a","objectKey":null,"sourceIPAddress":"1.2.3.4","awsRegion":"us-east-1","userType":"AssumedRole","userName":null,"principalId":"AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40","accessKeyId":"ASIA5FLZVX4OPVKKVBMX","userAgent":"[aws-cli\/1.18.136 Python\/3.8.5 Darwin\/19.5.0 botocore\/1.17.59]"}
{"timestamp":"2020-09-14T01:02:34.000Z","eventName":"GetObject","bucketName":"mordors3stack-s3bucket-llp2yingx64a","objectKey":"ring.txt","sourceIPAddress":"1.2.3.4","awsRegion":"us-east-1","userType":"AssumedRole","userName":null,"principalId":"AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40","accessKeyId":"ASIA5FLZVX4OPVKKVBMX","userAgent":"[aws-cli\/1.18.136 Python\/3.8.5 Darwin\/19.5.0 botocore\/1.17.59]"}
```

These enriched logs make it possible to follow the attacker’s steps in an almost narrative form, showing exactly how the S3 bucket was accessed and what data was taken.
---

## ✅ Summary of Step 4

After the enrichment step:

- The dataset is fully **flattened and standardized**
- S3 activity can be easily sorted by time, IP, bucket, or access key
- Reconnaissance (`ListObjects`) and exfiltration (`GetObject`) patterns are clearly visible
- The investigation now has a clean foundation for **timeline reconstruction** and **incident reporting**

The next step is to begin analyzing the enriched dataset to build the full narrative of the attack.
---

# Step 5: Analysis and Timeline Reconstruction

With the enriched S3 dataset created in the previous step, the investigation now shifts to analyzing attacker behavior and reconstructing the sequence of events. The IRP–DataAccess playbook emphasizes connecting access patterns, IAM identities, tooling, and timestamps to determine what happened, how it happened, and whether any data was exposed.

In this step, I review the enriched events to identify recon activity, data access, and exfiltration. Because the enriched dataset is fully flattened, it becomes much easier to identify behavioral patterns and follow the attacker’s actions over time.

---

## 5.1 Identifying the Attacker’s Identity

All enriched S3 events share the same IAM identity values:

- **userType**:`AssumedRole`
- **principalId**:`AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40`
- **accessKeyId**:`ASIA5FLZVX4OPVKKVBMX`


The suffix of the principalId (`i-0317f6c6b66ae9c40`) reveals that the assumed role belongs to an **EC2 instance profile**. This strongly indicates that an adversary obtained temporary credentials from this EC2 instance and is now using them externally.

---

## 5.2 Attacker Tooling and Environment

Every enriched event shows the same userAgent string:
```swift
[aws-cli/1.18.136 Python/3.8.5 Darwin/19.5.0 botocore/1.17.59]
```

This reveals several important details:

- The attacker used **AWS CLI**, not the AWS web console
- They used **Python 3.8.5** and **botocore 1.17.59**
- The host operating system is **Darwin 19.5.0 (macOS)**

This confirms that the attacker **exfiltrated the keys off the EC2 instance** and is now performing actions from their own macOS device, a strong indicator of credential theft rather than legitimate automation.

---

## 5.3 Source IP Address

All events originate from a single external IP: 
`1.2.3.4`

This is not an AWS internal address, further confirming that these requests were made from outside AWS using stolen credentials.

---

## 5.4 Reconnaissance Activity

Before accessing any objects, the attacker performs two waves of reconnaissance:

### Reconnaissance Wave 1 (early)
- `01:00:04`:ListBuckets
- `01:00:33`:ListObjects
- `01:00:53`:ListObjects
- `01:01:04`:ListObjects
- `01:01:50`:ListBuckets

### Reconnaissance Wave 2 (later)
- `01:12:40`:ListObjects
- `01:12:43`:ListObjects
- `01:13:20`:ListObjects


These repeated enumeration attempts suggest:

- The attacker was exploring available buckets
- They were identifying which objects existed
- They may have been testing permissions
- They revisited the bucket after some time possibly confirming continued access

This behavior is fully aligned with the tactics described in the *Unintended S3 Access* playbook.

---

## 5.5 Data Access and Exfiltration

The attacker retrieves the same object twice:
```makefile
01:02:34Z → GetObject: ring.txt
01:13:20Z → GetObject: ring.txt
```

This indicates:

- The file **ring.txt** is likely the adversary’s target
- Access was successful
- The attacker returned for a second copy, possibly:
  - verifying data integrity
  - testing persistence
  - confirming that the credentials still worked
  - exfiltrating to another location

The fact that both exfiltration events occur after enumeration strongly supports the hypothesis that the attacker intentionally accessed the bucket for data theft.

```jsonl
{"timestamp":"2020-09-14T01:02:34.000Z","eventName":"GetObject","bucketName":"mordors3stack-s3bucket-llp2yingx64a","objectKey":"ring.txt","sourceIPAddress":"1.2.3.4","awsRegion":"us-east-1","userType":"AssumedRole","userName":null,"principalId":"AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40","accessKeyId":"ASIA5FLZVX4OPVKKVBMX","userAgent":"[aws-cli\/1.18.136 Python\/3.8.5 Darwin\/19.5.0 botocore\/1.17.59]"}
{"timestamp":"2020-09-14T01:13:20.000Z","eventName":"GetObject","bucketName":"mordors3stack-s3bucket-llp2yingx64a","objectKey":"ring.txt","sourceIPAddress":"1.2.3.4","awsRegion":"us-east-1","userType":"AssumedRole","userName":null,"principalId":"AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40","accessKeyId":"ASIA5FLZVX4OPVKKVBMX","userAgent":"[aws-cli\/1.18.136 Python\/3.8.5 Darwin\/19.5.0 botocore\/1.17.59]"}
```

---

## 5.6 Timeline Reconstruction

Below is a chronological reconstruction of the attacker’s actions:

| Timestamp (UTC)           | Action        | Details                                  |
|---------------------------|---------------|-------------------------------------------|
| 2020-09-14 01:00:04       | ListBuckets   | Initial bucket enumeration                |
| 2020-09-14 01:00:33       | ListObjects   | Investigates S3 bucket contents           |
| 2020-09-14 01:00:53       | ListObjects   | Continued enumeration                     |
| 2020-09-14 01:01:04       | ListObjects   | Continued enumeration                     |
| 2020-09-14 01:01:50       | ListBuckets   | Re-checking bucket list                   |
| 2020-09-14 01:02:34       | GetObject     | First exfiltration of ring.txt            |
| 2020-09-14 01:12:40       | ListObjects   | Reconnaissance wave #2                    |
| 2020-09-14 01:12:43       | ListObjects   | Continued enumeration                     |
| 2020-09-14 01:13:20       | ListObjects   | Final enumeration before exfil            |
| 2020-09-14 01:13:20       | GetObject     | Second exfiltration of ring.txt           |

This timeline clearly shows:
1. Credential theft →
2. Reconnaissance →
3. Target identification →
4. Data exfiltration →
5. Revalidation →
6. Second exfiltration


This is a complete attack chain consistent with credential compromise.

---

## 5.7 Key Findings

From analyzing the enriched dataset, I determined:

- The adversary used stolen EC2 instance profile credentials.
- All activity was performed from a macOS machine via AWS CLI.
- The attacker’s source IP address remained consistent throughout.
- There were two separate waves of reconnaissance and exfiltration.
- The sensitive object **ring.txt** was downloaded twice.
- The sequence strongly aligns with the IRP–DataAccess playbook for unintended S3 access.

These findings confirm that the attacker accessed the S3 bucket intentionally, methodically, and with full awareness of the objects being exfiltrated.

---

## 5.8 Extended Search for Attacker Activity (Indicator Pivoting)

After enriching the S3 events, the next step was to determine whether the attacker performed any additional actions outside of S3. In real incident response workflows, this is known as **pivoting on indicators**, taking known malicious identifiers and searching the rest of the dataset to uncover related activity.

To perform a thorough investigation, I ran **three independent searches** across the full CloudTrail dataset using the following indicators extracted from the enriched S3 logs:

- **principalId**: identifies the compromised EC2 instance role  
- **accessKeyId**: identifies the stolen temporary credentials  
- **userAgent**: identifies the attacker's tooling (AWS CLI on macOS)

These three pieces of evidence act as stable identifiers for the attacker’s session.

I created a new script called `extended_search.py` that loads the full dataset and performs three separate pivot queries:

- **Pivot 1:** Search for all events with the same `principalId`
- **Pivot 2:** Search for all events with the same `accessKeyId`
- **Pivot 3:** Search for all events with the same `userAgent`

Each pivot is exported to its own JSONL file, and a combined JSONL file is created for consolidated review.

```python
# Extract nested fields for searching
    df["principalId"] = df["userIdentity"].apply(lambda x: safe_get(x, "principalId"))
    df["accessKeyId"] = df["userIdentity"].apply(lambda x: safe_get(x, "accessKeyId"))
    df["ua"] = df["userAgent"]

    print("\nRunning independent pivot searches...")

    # ---- Pivot 1: principalId ----
    pivot_principal = df[df["principalId"] == COMPROMISED_PRINCIPAL]
    save_jsonl(pivot_principal, OUT_PRINCIPAL)

    # ---- Pivot 2: accessKeyId ----
    pivot_access = df[df["accessKeyId"] == COMPROMISED_ACCESSKEY]
    save_jsonl(pivot_access, OUT_ACCESSKEY)

    # ---- Pivot 3: userAgent ----
    pivot_ua = df[df["ua"] == COMPROMISED_USERAGENT]
    save_jsonl(pivot_ua, OUT_USERAGENT)

    # Combined JSONL for full review
    combined = pd.concat([pivot_principal, pivot_access, pivot_ua],ignore_index=True)

    # Use eventID (hashable string) to drop duplicates safely
    if "eventID" in combined.columns:
        combined = combined.drop_duplicates(subset=["eventID"])

    save_jsonl(combined, OUT_COMBINED_JSON)
```

Running these searches ensures that I not only identify the S3-related behavior, but also verify whether the attacker interacted with any other AWS services (such as IAM, EC2, STS, or CloudFormation). This is critical for detecting privilege escalation attempts or lateral movement.

After reviewing all three pivot results, every matching event belonged to the same S3 activity already identified earlier in the investigation. No additional IAM, EC2, STS, or other API calls were made using the compromised credentials.

This confirms that the attacker:

- used a single stolen role session  
- performed two waves of S3 reconnaissance  
- downloaded the target file twice  
- **and did not attempt additional modifications or privilege escalation**

The extended search provides confidence that the attack was limited in scope but still involved unauthorized data access.

It’s important to note that this conclusion is scoped to the provided dataset. In a real-world response, the next step would be to run the same IOCs across a wider time range and additional log sources (for example, CloudTrail in other regions, VPC Flow Logs, or guardrails like GuardDuty). However, for this project’s log window, the IOC pivot supports a contained narrative: the compromised EC2 role was used specifically to discover and exfiltrate data from a single S3 bucket, with no further activity observed.

---

## 5.9 Next Steps

With the investigation complete, the next step is to produce a formal incident report summarizing what happened, the attacker’s behavior, the potential impact, and recommended remediation actions.

This will be covered in **Step 6: Incident Report**.

---
# 6. Conclusion

This investigation followed the IRP–DataAccess workflow end-to-end, starting from raw CloudTrail logs and progressing through enrichment, indicator extraction, and IOC-based pivoting across the full dataset. By reconstructing the attacker’s activity with structured analysis rather than intuition alone, we were able to determine both **what happened** and **what did not** happen during the incident.

The evidence shows a clear and consistent sequence of actions:

- A compromised EC2 instance role (`MordorNginxStack-BankingWAFRole-9S3E0UAE1MM0`) was used to authenticate to AWS without MFA.
- The attacker enumerated the victim’s S3 buckets using `ListBuckets`, then focused exclusively on `mordors3stack-s3bucket-llp2yingx64a`.
- They repeatedly issued `ListObjects` requests to understand the bucket’s contents and permissions.
- They performed two successful `GetObject` operations to retrieve **ring.txt**, which appears to be the target of the exfiltration.
- No IAM changes, privilege escalation attempts, or activity against EC2, STS, Lambda, DynamoDB, or any other AWS service were observed.
- Extended IOC-based searching confirmed that the attacker’s `principalId`, `accessKeyId`, and `userAgent` never appeared outside of S3 activity within this dataset.

In other words, the logs support a **single-vector, single-asset compromise**. The attacker obtained access to an EC2 role’s temporary credentials, used those credentials to enumerate and exfiltrate data from one S3 bucket, and did not perform lateral movement or expand their foothold beyond this initial access.

While the scope of the attack was limited in this dataset, the root cause, an EC2 instance profile with broad S3 permissions and no defense-in-depth protections such as MFA enforcement, GuardDuty coverage, or IAM least-privilege, highlights the importance of strengthening cloud access controls to reduce blast radius. 

**The final takeaway is clear:**  
The attacker succeeded not because of sophistication, but because the environment trusted an EC2 role too much and monitored it too little.

