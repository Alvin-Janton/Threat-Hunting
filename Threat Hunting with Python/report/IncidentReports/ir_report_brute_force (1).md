| Incident ID | Incident Type | Date & Time (UTC) | Severity | Incident Handler | Affected System | Malware Found |
|-------------|---------------|-------------------|----------|------------------|-----------------|---------------|
| IR-2023-003 | Brute Force   | 2023-05-07 18:00  | High     | Mark Adams       | Server-001      | PersistenceMal|

## Incident Description

An attacker attempted to brute force into the network using a tool like Hydra. After gaining access to the affected system (Server-001), the attacker planted a malware to maintain persistence. The malicious activity was caught by the Intrusion Detection System (IDS).

## Indicators of Compromise (IoCs)

| Indicator Type   | Indicator Value                            | Confidence | Source     |
|------------------|--------------------------------------------|------------|------------|
| Tool Signature   | Hydra (Brute Force Tool)                   | High       | IDS        |
| Malware Hash     | 5a064113d8863eb34253dbee7a271974 (MD5)      | High       | AntiVirus  |
| Attacker IP      | 95[.]181[.]152[.]9                              | High       | IDS        |
| Malicious Domain | hxxp://epcdiagnostic[.]com  | High       | IDS        |

_Note: For security reasons, the malicious domain URL is obfuscated._

## Incident Timeline

| Time (UTC)  | Action Taken                                    | Performed By |
|-------------|-------------------------------------------------|--------------|
| 18:05       | Initial detection of brute force attempt        | IDS          |
| 18:10       | Intrusion Detection System alerts reviewed      | Mark Adams   |
| 18:15       | Affected system isolated from the network       | Mark Adams   |
| 18:20       | System backup initiated                         | Mark Adams   |
| 18:35       | Malware analysis and identification             | Mark Adams   |
| 18:50       | Malware removal and system restoration          | Mark Adams   |
| 19:20       | System integrity and functionality confirmed    | Mark Adams   |
| 19:30       | Affected system returned to normal operation    | Mark Adams   |

## Lessons Learned & Recommendations

- Implement strong and unique passwords for all user accounts, and consider using multi-factor authentication (MFA).
- Regularly review and update firewall rules and IDS/IPS signatures to detect and block known attack patterns.
- Monitor network traffic and access logs for signs of brute force attempts and other suspicious activities.
- Provide ongoing cybersecurity awareness training for employees to recognize social engineering attempts and handle them appropriately.
- Keep systems and software up-to-date with the latest patches.
- Implement endpoint protection and network monitoring solutions to detect and prevent malicious activities.
