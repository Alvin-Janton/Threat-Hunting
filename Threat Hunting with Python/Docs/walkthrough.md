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


