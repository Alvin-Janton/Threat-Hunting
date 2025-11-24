| Incident ID | Incident Type | Date & Time (UTC) | Severity | Incident Handler | Affected User | System Affected |
|-------------|---------------|-------------------|----------|------------------|---------------|-----------------|
| IR-2023-001 | Malware       | 2023-05-07 14:30  | High     | John Doe         | Jane Smith    | PC-001          |

## Incident Description

A phishing email was received by the user, Jane Smith, containing a malicious attachment. Upon opening the attachment, malware was executed on the affected system (PC-001). The malware was identified as a known ransomware variant.

## Indicators of Compromise (IoCs)

| Indicator Type  | Indicator Value                              | Confidence | Source     |
|-----------------|----------------------------------------------|------------|------------|
| Malware Hash    | 44d88612fea8a8f36de82e1278abb02f (MD5)        | High       | AntiVirus  |
| Malicious IP    | 45[.]142[.]166[.]228                          | High       | VirusTotal |

## Incident Timeline

| Time (UTC)  | Action Taken                                  | Performed By |
|-------------|-----------------------------------------------|--------------|
| 14:32       | Initial identification of the malware incident | John Doe     |
| 14:35       | User informed and advised to disconnect PC    | John Doe     |
| 14:40       | Affected system isolated from the network     | John Doe     |
| 14:45       | System backup initiated                       | John Doe     |
| 15:00       | Malware analysis and identification           | John Doe     |
| 15:15       | Malware removal and system restoration        | John Doe     |
| 15:45       | System integrity and functionality confirmed  | John Doe     |
| 16:00       | User informed and system returned to user     | John Doe     |

## Lessons Learned & Recommendations

- Implement stronger email filtering to block malicious emails and attachments.
- Provide ongoing cybersecurity awareness training for employees to recognize phishing attempts and handle them appropriately.
- Regularly back up critical systems and data, ensuring that backups are stored offline and tested periodically.
- Keep systems and software up-to-date with the latest patches.
- Implement endpoint protection and network monitoring solutions to detect and prevent malicious activities.
