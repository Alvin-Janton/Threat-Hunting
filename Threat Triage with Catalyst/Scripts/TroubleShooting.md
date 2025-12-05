# Troubleshooting Guide

This guide provides solutions to the most common issues encountered when deploying or running the Catalyst IR stack using the `setup_catalyst.sh` installer. It assumes you are running on a Unix/Linux system (e.g., Ubuntu EC2, Debian, Fedora, etc.) with Docker and Docker Compose installed.
---

## 🔧 Helpful Commands for Troubleshooting

These commands are commonly used when diagnosing issues within the Catalyst stack:

### Docker Basics

```bash
docker ps                    # List running Docker containers 
docker compose ps            # List all running Docker containers in the docker-compose.yml
docker logs <container>      # Shows the logs of the specified container
docker exec -it <container>  # Execute a command in a running Docker container
```

---

### Service-specific logs

Shows the most recent logs in a Container:

```bash
docker logs catalyst-ir-stack-catalyst-1 --tail=100
docker logs catalyst-ir-stack-authelia-1 --tail=100
docker logs catalyst-ir-stack-nginx-1 --tail=100
docker logs catalyst-ir-stack-arangodb-1 --tail=100
docker logs catalyst-ir-stack-minio-1 --tail=100
```

---

### Connectivity Tests (Inside Containers)

From inside nginx:

```bash
docker exec -it catalyst-ir-stack-nginx-1 curl -v http://catalyst:8000/ # Test Nginx → Catalyst
docker exec -it catalyst-ir-stack-catalyst-1 curl -v http://arangodb:8529/_api/version # Test Catalyst → ArangoDB
docker exec -it catalyst-ir-stack-nginx-1 sh -c 'curl -v http://authelia:9091/' # Test Nginx → Authelia
```

---

### View environment variables inside a container
```bash
docker exec -it catalyst-ir-stack-catalyst-1 env
```

---

### ⚠ Danger Zone: Removing Volumes

```bash
docker volume ls
docker volume rm <volume-name>
```

---

## Common Issues & Their Solutions

---

### 1️⃣ ArangoDB Password Mismatch

Symptoms

- Catalyst redirects to /ui/ but fails on login.

- Nginx shows “502 Bad Gateway.”

- Browser shows “Cannot connect.”

- Catalyst logs show:

```sql
could not connect to database: not authorized to execute this request
retrying in 10 seconds
```

This means **Catalyst is using a password that does not match the existing ArangoDB volume** from a previous installation.

✅ Fix

Delete the ArangoDB volume and rebuild the stack:

```bash
docker compose down --volumes
docker compose up -d
```

Make sure you when running the installer you read and accept all prompts, especially those involving overwriting or generating secrets.

---

### 2️⃣ Missing or Incorrect /etc/hosts Entries
Symptoms

Browser says:

- “refused to connect”

- “This site cannot be reached”

- DNS_PROBE_FINISHED_NXDOMAIN

- Curl from host returns nothing.

**Cause**

Domains like:

```text
catalyst.localhost
authelia.localhost
```

are not mapped to 127.0.0.1, or remote domains aren’t mapped to your EC2 instance.

**🔍 Check hosts file**

Linux/macOS:
```bash
cd /etc
sudo hosts
```

Windows (Admin):

```bash
cd C:\Windows\System32\drivers\etc\
cat hosts
```

Should contain:

```text
127.0.0.1 catalyst.localhost
127.0.0.1 authelia.localhost
```

Remote server (e.g., EC2):

Your local machine needs the EC2 public IP:

```text
3.227.239.104 catalyst.testing.net
3.227.239.104 authelia.testing.net
```

❗ Do NOT add:

Ports

Protocols

Example of incorrect entries:

```text
127.0.0.1 https://catalyst.localhost
127.0.0.1 catalyst.localhost:443
```

---

### 3️⃣ Stale Browser Cookies

Symptoms

Upon login, Catalyst returns:

```json
{"error":"state missing"}
```

**Cause**

You previously authenticated to the same domain on a completely different instance or deployment.
Authelia issues a new OIDC authorization request, but Catalyst has stale browser cookies and can't match the stored state.

**✔ Fix**

- Open an incognito/private window
or

- Clear cookies for:

- `catalyst.<domain>`

- `authelia.<domain>`

Then reload Catalyst.

---

### 4️⃣ Catalyst Starts but Returns 502 via Nginx
**Symptoms**

- `curl -k https://catalyst.localhost` → `502 Bad Gateway`

Authelia works fine.

**Diagnose Nginx → Catalyst Connectivity**

Run:

```bash
docker exec -it catalyst-ir-stack-nginx-1 sh -c 'curl -v http://catalyst:8000/'
```


| **Output**                       | **Meaning**                                   |
|----------------------------------|-----------------------------------------------|
| *Connected + `302 Found → /ui/`* | Catalyst is healthy                           |
| *Connection refused*             | Catalyst isn't listening **or** has crashed   |
| *Could not resolve host*         | Docker DNS is broken                          |

**Fixes**:

- Restart stack:
```bash
docker compose restart catalyst
```

- Validate ENV values inside Catalyst:
```bash
docker exec -it catalyst-ir-stack-catalyst-1 env
```

---

### 5️⃣ ArangoDB Fails to Start (Port Conflict or Corrupted DB)

**Symptoms:**
- Catalyst logs show connection refused:
```sql
could not connect to database: dial tcp 172.x.x.x:8529: connect: connection refused
```

**Fix:**
Try restarting ArangoDB:
```bash
docker compose restart arangodb
```

If still failing, volume is likely corrupted:
```bash
docker compose down --volumes
docker compose up -d
```

---

### 6️⃣ Authelia Not Issuing OIDC Tokens

Symptoms:

UI loads, but login flow breaks on callback.

**Check OIDC URLs inside Catalyst:**
```bash
docker exec -it catalyst-ir-stack-catalyst-1 env | grep OIDC
```

Should show:
```ini
OIDC_ISSUER=http://authelia:9091
OIDC_AUTH_URL=https://<your-domain>/api/oidc/authorization
```

If domains don’t match your current installation, fix .env and recreate containers.

---

## ✔ Final Notes

- The majority of problems come from:

1. ArangoDB volumes persisting old passwords

2. Missing /etc/hosts entries

3. Stale browser cookies

4. incorrect environment variables after re-running the script

- If all else fails:
```bash
docker compose down --volumes
rm -rf catalyst-ir-stack # If different replace with correct directory name
./setup_catalyst.sh
```






