# **Incident Report — Malicious SolarWinds IOC Activity Detected in Network Logs**

---

| **Field**               | **Details**                                                |
|------------------------|-------------------------------------------------------------|
| **Incident ID**        | IR-2024-SW-001                                              |
| **Incident Type**      | IOC Match / Command-and-Control Communication               |
| **Date Range Observed**| 2024-03-03 — 2024-03-05                                     |
| **Severity**           | High                                                        |
| **Incident Handler**   | Alvin Janton                                                |
| **Affected System(s)** | Multiple internal hosts (see asset list below)              |
| **Environment**        | On-Premises / Simulated Enterprise Network                  |

---

## **Incident Description**

During a threat-hunting investigation, outbound network logs were analyzed in Splunk and correlated against known malicious indicators from the **SolarWinds supply-chain compromise IOC feed**.

After creating a lookup table of SolarWinds-related IP addresses and correlating them with outbound proxy events, the analysis identified **three unique malicious IP addresses** contacted by internal systems.

VirusTotal validation showed multiple detections per IP (e.g., *10/95*), confirming high-confidence malicious behavior.

---

## **Indicators of Compromise (IoCs)**

| **IOC Type** | **Value**         | **Description**               | **Confidence** | **Source**                |
|--------------|-------------------|-------------------------------|----------------|---------------------------|
| IP           | `5[.]252[.]177[.]25`    | C2 malware / call-home        | High           | SolarWinds IOC Feed + VirusTotal  |
| IP           | `13[.]59[.]205[.]66`    | Malware repository server     | High           | SolarWinds IOC Feed + VirusTotal  |
| IP           | `54[.]215[.]192[.]52`   | Malware repository server     | High           | SolarWinds IOC Feed + VirusTotal  |

All IPs show multiple vendor detections in VirusTotal.

---

## **Impacted Hosts & Events**

### 1. 5.252.177.25 — C2 Server (3 matches)

| **Date**       | **Time**   | **Hostname**          |
|----------------|------------|------------------------|
| 2024-03-05     | 07:11:28   | LN-SolarStrike-14      |
| 2024-03-03     | 07:37:28   | MX-SolarStorm-136      |
| 2024-03-03     | 07:04:28   | WS-SolarLight-943      |

---

### 2. 13.59.205.66 — Malware Repository (1 match)

| **Date**       | **Time**   | **Hostname**         |
|----------------|------------|-----------------------|
| 2024-03-04     | 06:57:28   | WS-SolarWave-212      |

---

### 3. 54.215.192.52 — Malware Repository (1 match)

| **Date**       | **Time**   | **Hostname**           |
|----------------|------------|-------------------------|
| 2024-03-05     | 07:10:28   | LN-SolarShadow-552      |

---

## **Incident Timeline**

| **Date**       | **Time** | **Event Description**                               |
|----------------|----------|------------------------------------------------------|
| 2024-03-03     | 07:04    | First observed C2 callback (5.252.177.25)           |
| 2024-03-03     | 07:37    | Second callback from different host                 |
| 2024-03-04     | 06:57    | Host contacts repository IP (13.59.205.66)          |
| 2024-03-05     | 07:10    | Host contacts second repository IP (54.215.192.52)  |
| 2024-03-05     | 07:11    | Third C2 callback detected                          |

---

## Impact Assessment

### Affected Assets
Five internal systems communicated with SolarWinds malicious infrastructure:

- LN-SolarStrike-14  
- MX-SolarStorm-136  
- WS-SolarLight-943  
- WS-SolarWave-212  
- LN-SolarShadow-552  

### Risk Level: High

**Reasons:**

- Confirmed communication with known SolarWinds attacker C2 servers  
- Multiple hosts affected  
- Repository traffic suggests staged malware download  
- Repeated beaconing over multiple days  

### Potential Impact Includes:

- Execution of malicious payload  
- Data exfiltration  
- Backdoor/persistence installation  
- Lateral movement  

---

## Root Cause Analysis

| **Category**              | **Description**                                      |
|---------------------------|------------------------------------------------------|
| Supply-Chain Compromise   | Likely infected via SolarWinds-style trojan update   |
| Outbound C2 Traffic       | Hosts contacted known malicious IP infrastructure    |
| Lack of Detection         | No alerting on outbound malicious IP traffic        |

---

## Lessons Learned & Recommendations

### Threat Detection
- Automate IOC correlation (scheduled searches, lookups)  
- Enable continuous monitoring for C2 behavior  
- Create alerts for suspicious outbound IP categories  

### Endpoint Security
- Conduct forensic review of compromised hosts  
- Reimage machines if necessary  
- Deploy EDR to detect trojanized updates  

### Network Defense
- Block known malicious IP categories  
- Enforce strict egress filtering (deny-by-default)  
- Monitor DNS + HTTP/S for IOC patterns  

### Intelligence Operations
- Frequently update threat intelligence feeds  
- Automate IOC ingestion into Splunk  
- Validate intel against internal network activity  

---

## Final Assessment

This investigation confirms that multiple hosts communicated with verified SolarWinds C2 infrastructure. With repeated beaconing events, repository access, and VirusTotal-confirmed IoCs, this qualifies as a **confirmed security incident** requiring:

- **Immediate containment**  
- **Forensic triage of affected hosts**  
- **Network-level blocking**  
- **Long-term remediation and hardening**
