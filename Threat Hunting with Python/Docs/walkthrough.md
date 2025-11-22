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

## 🔍 2.1 Previewing Raw JSON Events

Before converting anything into pandas, I wanted to get a sense of what a single CloudTrail event looks like. Each event contains nested fields such as `userIdentity`, `eventSource`, `eventName`, `requestParameters`, and timestamps.  

Instead of printing the logs directly to the terminal—which becomes unreadable due to their length—I wrote a small helper function that extracts the first few events and writes them to a separate JSON file. This keeps things clean and allows me to reference the preview later in the project.

👉 **Place code block for `preview_raw_events()` here**

👉 **Place screenshot of `raw_preview.json` here**

This preview confirmed that the dataset contains mixed AWS activity (IAM events, EC2 events, and S3 events), which aligns with the scenario of attackers using compromised EC2 credentials.

---

## 📊 2.2 Loading the Dataset Into a DataFrame

Next, I loaded the full dataset into a pandas DataFrame. Pandas automatically parses each JSON object as a row and handles nested structures as Python dictionaries.

👉 **Place code block for `load_as_dataframe()` here**

Once loaded, I exported three important views into a Markdown file:

- `df.head()` — first 5 rows  
- `df.info()` — dataset size, column types, null counts  
- `df.columns` — the list of available fields  

This approach produces a clean Markdown summary instead of flooding the terminal with output.

👉 **Place screenshot of `df_preview.md` here**

---

## 📝 2.3 Generating a Dataset Overview File

To organize the results, I built a helper function that writes all the structural information into a single Markdown file inside the `data/` folder. This file acts as a quick reference for the rest of the investigation.

👉 **Place code block for `generate_markdown_summary()` here**

The resulting file includes:
- A preview of the data  
- The full schema  
- All column names in the dataset  

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
