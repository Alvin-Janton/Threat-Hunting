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
- `SolarWindsIOC` → *SolarWindsIOCs.csv*

![picture](../report/images/Ingesting%20Network%20Log%20.png)

---

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

## Step 2: Dataset Exploration

After ingesting both datasets into Splunk, the next step is to verify that Splunk parsed the data correctly—especially the **Date**, **Time**, and **IP Address** fields in the network logs. These fields are essential for determining the *who*, *what*, and *when* behind the activity we are investigating.

---

## Step 2.1: Verifying Ingestion

To verify that Splunk correctly ingested and parsed both files, I ran two simple searches to view the first five events from each dataset.

---

### 🔍 Network Log Preview (`NetworkProxyLog02.csv`)

```sql
index="threat_hunting" host="network_proxy" | head 5
```

This query returns the first five events from the network proxy log, sorted by Splunk’s default ordering (based on the internal timestamp field `_time`).

![pictute](../report/images/First%20Five%20Lines%20Network.png)

> **Note:** Splunk automatically orders results by the internal `_time` field, **not** by the original line order of the CSV.  
> Because `_time` defaults to the moment the file was ingested, `head` returns the first five **ingested** events—not the first five rows from the raw file.  
> This is normal behavior and does not affect the investigation.

---

### 🔍 IOC Log Preview (`SolarWindsIOCs.csv`)

For the IOC file, I used a similar query, but replaced `head` with `tail`.  
This is because the IOC file does not include its own timestamp fields, so Splunk assigns `_time` based on ingestion time.  
Splunk may display the file in **reverse order**, meaning the original first rows appear last.

```sql
index="threat_hunting" host="SolarWindsIOC" | tail 5
```

![picture](../report/images/First%20Five%20Lines%20IOC.png)

---

With these previews, I confirmed that Splunk successfully ingested both datasets and preserved all important fields, including the `Date`, `Time`, `Computer Name`, and `IP Address` columns in the network 
logs.

---

## Step 3: IOC Correlation

Now that the datasets are successfully ingested and verified, I can begin searching for indicators of compromise (IoCs) within the network logs. To make this process more efficient, I will first extract only the **IP-based IOCs** from the SolarWinds intelligence feed and store them in a lookup table. I can then use that lookup to quickly identify all matching malicious IPs in the network traffic.

---

### Step 3.1: Filter Down to Only IP-Based IOCs

To begin, I run a query in **Search & Reporting** that returns only the IOC entries where the `Indicator_type` is `"ip"`.

```sql
index="threat_hunting" source="SolarWindsIOCs.csv" Indicator_type="ip"
| table "IP Address" Note
```

This query scans all entries in the SolarWindsIOC source file, filters for IP-based indicators, and displays the relevant fields. The result is a clean preview of what the lookup table will contain.

You should see:

- IP addresses in the `IP Address` column  
- Malware descriptions in the `Note` column  

This confirms that Splunk extracted the IP IOCs correctly.

![picture](../report/images/Lookup%20Table%20Output.png)

---

### Step 3.2: Create the Lookup Table

Once I verified the IP indicators, I generated the lookup table by running:

```sql
index="threat_hunting" source="SolarWindsIOCs.csv" Indicator_type="ip"
| rename "IP Address" AS ip
| table ip Note
| outputlookup solarwinds_ioc_ips.csv
```

This performs several actions:

- `rename "IP Address" AS ip`  
  Simplifies the field name so it can be used in lookups.

- `table ip Note`  
  Keeps only the essential fields.

- `outputlookup solarwinds_ioc_ips.csv`  
  Saves the results as a lookup file named `solarwinds_ioc_ips.csv` inside Splunk.

If the command succeeds, Splunk displays a confirmation message that the lookup file was created.

---

### Step 3.3: Create the Lookup Definition

For Splunk to use the lookup file during searches, I must register it as a lookup definition:

1. Go to **Settings → Lookups → Lookup definitions**
2. Click **Add new**
3. Fill in the following:
   - **Name:** `solarwinds_ioc_ips`
   - **Type:** File-Based
   - **Lookup file:** `solarwinds_ioc_ips.csv`
4. Save the definition

After saving, the `solarwinds_ioc_ips` lookup becomes available for use in any SPL query.

![picture](../report/images/Lookup%20Definition.png)

---

### Step 3.4: Using the Lookup to Find Matches

With the lookup definition created, I can now use it to hunt for all IP matches inside the network logs.

```sql
index="threat_hunting" source="NetworkProxyLog02.csv"
| lookup solarwinds_ioc_ips ip AS "IP Address" OUTPUT Note
| where isnotnull(Note)
| table Date Time "Computer Name" "IP Address" Note
```
>Note: Set the **Time Range** to **All Time**, since the network logs were recorded in March 2024.
This query works as follows:

- Searches only the network proxy log
- Checks each event’s `"IP Address"` field against the lookup list
- Adds the `Note` field from the lookup to matching events
- Filters out all events that did not match
- Displays the date, time, computer name, and malicious IP information

> **Note:** Set the **Time Range** to **All Time**, since the network logs were recorded in March 2024.

Running the query reveals five matching events, corresponding to three unique malicious IP addresses.

![picture](../report/images/Lookup%20Result.png)

---

# Step 4: Analysis

With the lookup table in place, I used it to identify all malicious outbound connections in the network proxy logs. The results revealed **three unique SolarWinds-related IP addresses**, matching the intelligence feed and confirming that several hosts in the network communicated with known malicious infrastructure.

Below is a breakdown of each matched IP, including the date, time, and computer name associated with the events.

---

## 🔍 Match #1 — 5.252.177.25
**Threat Type:** C2 malware/callhome

This IP appeared **three times** in the network logs, indicating repeated communication attempts to a known command-and-control (C2) server. The affected systems and timestamps are:

- **2024-03-05 07:11:28 — LN-SolarStrike-14**
- **2024-03-03 07:37:28 — MX-SolarStorm-136**
- **2024-03-03 07:04:28 — WS-SolarLight-943**

---

## 🔍 Match #2 — **13.59.205.66**
**Threat Type:** C2 malware/repository

This IP appears **once** in the logs and is associated with malware retrieval or staging.  
This suggests the host contacted a malicious repository server.

- **2024-03-04 06:57:28 — WS-SolarWave-212**

---

## 🔍 Match #3 — **54.215.192.52**
**Threat Type:** C2 malware/repository

This IP also appears **once** and is linked to known SolarWinds attacker infrastructure.

- **2024-03-05 07:10:28 — LN-SolarShadow-552**

---

## 📘 Summary of IOC Findings

Across all network activity, I identified:

- **3 unique malicious SolarWinds IP addresses**
- **5 total events** associated with those IPs
- **5 different internal systems** that communicated with malicious infrastructure

These findings validate that compromised hosts within the simulated network reached out to attacker-controlled servers, consistent with SolarWinds-style supply chain compromise behavior.

---

# Step 5: Dashboard Creation


