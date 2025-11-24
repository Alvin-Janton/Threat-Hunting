# Incident Report — Unauthorized S3 Data Access via Compromised EC2 Instance

| Field               | Details                                                         |
|---------------------|-----------------------------------------------------------------|
| **Incident ID**     | IR-2020-S3-001                                                  |
| **Incident Type**   | Unauthorized Access / Credential Misuse                         |
| **Date & Time (UTC)** | 2020-09-14 01:00 — 01:13 UTC                                 |
| **Severity**        | High                                                            |
| **Incident Handler**| Alvin Janton                                                     |
| **Affected Resource(s)** | EC2 Instance (Reverse Proxy) / S3 Bucket `mordors3stack-s3bucket-llp2yingx64a` |
| **Environment**     | AWS Cloud (EC2, STS, IAM, S3)                                   |

---

## Incident Description

This incident involves an unauthorized entity abusing a misconfigured EC2 instance that exposed a reverse proxy, allowing an attacker to execute AWS CLI calls from the host. The EC2 instance’s instance profile role had no MFA requirements and provided permission to access an S3 bucket.

The attacker used the AWS CLI (macOS user agent):
```swift
aws-cli/1.18.136 Python/3.8.5 Darwin/19.5.0 botocore/1.17.59
```

Using the EC2 instance’s instance profile role, the attacker:
- Assumed the IAM role attached to the EC2 instance
(principalId: `AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40`)
- Enumerated S3 buckets and objects
(`ListBuckets`, `ListObjects`)
- Exfiltrated the object `ring.txt` using GetObject

All S3 activity was signed using the same compromised access key:
`ASIA5FLZVX4OPVKKVBMX`

---

## Incident Visual

Visual showing how the attack flow through the AWS Environment
![Picture](./images/Exfiltration_Diagram.png)

---

## Indicators of Compromise (IoCs)

| Indicator Type           | Value                                                            | Confidence                           | Source     |
| ------------------------ | ---------------------------------------------------------------- | ------------------------------------ | ---------- |
| **Principal ID**         | `AROA5FLZVX4OAMSW6BCRH:i-0317f6c6b66ae9c40`                      | High                                 | CloudTrail |
| **Temporary Access Key** | `ASIA5FLZVX4OPVKKVBMX`                                           | High                                 | CloudTrail |
| **User Agent**           | `[aws-cli/1.18.136 Python/3.8.5 Darwin/19.5.0 botocore/1.17.59]` | High                                 | CloudTrail |
| **Source IP**            | `1.2.3.4`                                                        | Low (EC2 proxy hides true origin) | CloudTrail |
| **Object Exfiltrated**   | `s3://mordors3stack-s3bucket-llp2yingx64a/ring.txt`              | High                                 | CloudTrail |
| **MFA Status**           | `mfaAuthenticated: false`                                        | High                                 | CloudTrail |

---

## Incident Timeline

| Time (UTC)   | Event                        | CloudTrail EventName        | Notes                       |
| ------------ | ---------------------------- | --------------------------- | --------------------------- |
| **01:00:04** | Bucket enumeration begins    | `ListBuckets`               | Attack starts               |
| **01:00:33** | Object listing begins        | `ListObjects`               | Multiple listings follow    |
| **01:00:53** | Continued object enumeration | `ListObjects`               | —                           |
| **01:01:04** | Enumeration continues        | `ListObjects`               | —                           |
| **01:01:50** | Second bucket listing        | `ListBuckets`               | Confirms attacker recon     |
| **01:02:34** | **Data exfiltration**        | `GetObject`                 | `ring.txt` downloaded       |
| **01:12:40** | Additional enumeration       | `ListObjects`               | Possibly confirming exfil   |
| **01:12:43** | Enumeration                  | `ListObjects`               | —                           |
| **01:13:20** | Final enumeration & exfil    | `ListObjects` + `GetObject` | `ring.txt` downloaded again |

---

## Impact Assessment

### Affected Resources

- **S3 Bucket:** `mordors3stack-s3bucket-llp2yingx64a`
- **EC2 Instance:** Misconfigured reverse proxy enabled unauthorized execution

### Data Accessed

- Repeated enumeration of the bucket
- At least two confirmed downloads of sensitive object: `ring.txt`

### Access Method

- AWS CLI using temporary credentials from the EC2 instance’s IAM role
- No MFA enforced
- Valid IAM role permissions allowed S3 access

### Risk Level

**High**, due to
- Successful sensitive data exfiltration
- Credential compromise
- Lack of MFA
- Use of instance profile role outside intended trust boundaries

---

## Root Cause Analysis

| Category                 | Findings                                                                                  |
| ------------------------ | ----------------------------------------------------------------------------------------- |
| **IAM Misconfiguration** | EC2 instance profile role allowed S3 access and had no MFA enforcement.                   |
| **Instance Exposure**    | EC2 acted as a reverse proxy, allowing external attacker execution.                       |
| **Lack of Monitoring**   | No CloudWatch alerts for unusual S3 API patterns (burst of ListObjects, unauthorized IP). |
| **Credential Abuse**     | Temporary credentials auto-issued to EC2 instance were abused.                            |

---

## Lessons Learned & Recommendations

### Identity & Access Management

- Enforce MFA for all IAM role assumptions (where technically possible)
- Apply resource-level least privilege for instance profiles
- Prohibit EC2 instances from accessing high-sensitivity buckets unless strictly necessary

---

### Logging & Monitoring

Establish CloudWatch alarms for:

- Unusual S3 data-access patterns
- High-volume `ListObjects` requests
- Unexpected UserAgents or non-EC2 IP addresses

---

### Network & Architecture

- Prevent EC2 reverse proxy exposure
- Use VPC endpoints for S3 with access control

---

### Detection Engineering

Create detection rules for:

- AccessKey reuse outside expected contexts
- AWS CLI macOS user agent in a Linux EC2 environment
- Repeated listing followed by object downloads

---

### General Security Hygiene

- Regular IAM audits
- Implement continuous threat modeling for cloud systems
- Require logging of instance metadata service usage (IMDS)
