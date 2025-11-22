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

This playbook focuses on responding to suspicious or unintended access to AWS data stores such as S3 — which aligns perfectly with the dataset being analyzed.

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

- `df.head()` — first 5 rows  
- `df.info()` — dataset size, column types, null counts  
- `df.columns` — the list of available fields


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

