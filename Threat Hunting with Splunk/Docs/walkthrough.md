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

# Step 1: Setup

To begin this project, I need to install and configure Splunk on my local device and ingest the datasets required for the investigation.

---

## 🔧 Install Splunk

To install Splunk, I navigated to **https://www.splunk.com/** and selected **Trials & Downloads**.

![picture](../report/images/Splunk%20Home%20Page.png)

From there, I clicked on the **Free Trial** option under **Splunk Enterprise**, created an account, and downloaded the installation package for my operating system.

![picture](../report/images/Splunk%20Download%20Page.png)

After the download completed, I used the installation wizard to finalize setup.  
Once installation finished, the Splunk login page automatically launched.  
After entering my credentials, I was greeted by the Splunk Enterprise home page:

![picture](../report/images/Splunk%20Enterprise%20Home%20Page.png)

---

## 📥 Ingesting the Logs

Next, I ingested both CSV files into Splunk and ran a basic search to confirm successful ingestion.

From the home page, I scrolled down to **Common Tasks** and selected **Add Data**.  
Then, I chose the **Upload** option to upload each CSV file individually.

![picture](../report/images/Upload%20Data.png)

Splunk typically detects CSV files automatically, but the **Source Type** field can be manually configured if needed.

For this project, I created a dedicated index called **threat_hunting** to store both datasets.  
I also assigned each file a unique sourcetype to make the investigation easier:

- `network_proxy` → *NetworkProxyLog02.csv*
- `solarwinds_ioc` → *SolarWindsIOCs.csv*

![picture](../report/images/Ingesting%20Network%20Log%20.png)

![picture](../report/images/Ingesting%20IoC%20Log.png)

Once the upload finished, I verified ingestion using a simple search in the **Splunk Search & Reporting** app.

```sql
index=threat_hunting | stats count by sourcetype
```

This query returns the total number of events Splunk recorded for each sourcetype in the `threat_hunting` index.  
Each event corresponds to one parsed line of the CSV file (excluding headers, and blank lines).

Since the network log contains roughly **1,000 records** and the SolarWinds IOC file contains **43 records**, the results confirm that both files were successfully ingested.

> **Note:** Make sure your time range is set to **All time**, since the network logs use timestamps from **March 2024** and will not appear under “Last 24 hours.”


![Picture](../report/images/Simple%20SPL%20Query.png)

---





