#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "=== Catalyst IR Stack Installer ==="

# ---------------------------
# 0. Simple error trap
# ---------------------------

on_error() {
  echo
  echo "[ERROR] Installation failed. See messages above for details."

  # Only show the logs hint if these vars are already defined
  if [[ -n "${DC_STR-}" && -n "${INSTALL_DIR-}" ]]; then
    echo "[HINT] You can check container logs with:"
    echo "       cd \"$INSTALL_DIR\" && $DC_STR logs -f"
  fi
}
trap on_error ERR

# Optional: warn if common ports are already in use
check_port_in_use() {
  local port="$1"
  if command -v lsof >/dev/null 2>&1; then
    if lsof -Pi :"$port" -sTCP:LISTEN >/dev/null 2>&1; then
      echo "[WARN] Port $port appears to be in use on this host."
      echo "       The nginx container may fail to bind to port $port."
    fi
  fi
}

check_arango_volume() {
    local ARANGO_VOL_NAME="catalyst-ir-stack_arangodb"  # change if needed

    if docker volume inspect "$ARANGO_VOL_NAME" >/dev/null 2>&1; then
        echo "-----------------------------------------------------------------------"
        echo "[WARNING] Existing ArangoDB Docker volume detected: $ARANGO_VOL_NAME"
        echo ""
        echo "ArangoDB is already initialized and WILL IGNORE any new root password."
        echo "If .env contains a different ARANGO_ROOT_PASSWORD than the one used"
        echo "when this volume was first created, Catalyst will fail to authenticate."
        echo ""
        echo "Options:"
        echo "  1) Delete the volume for a clean install:"
        echo "         docker volume rm $ARANGO_VOL_NAME"
        echo ""
        echo "  2) Keep the existing volume but ensure .env uses the SAME password."
        echo ""
        echo -n "Do you want to continue using the existing ArangoDB volume? (yes/no): "
        read -r ARANGO_CONTINUE

        if [[ "$ARANGO_CONTINUE" != "yes" ]]; then
            echo "[ABORTED] Delete the volume or fix .env before rerunning the installer."
            exit 1
        fi

        echo "[INFO] Proceeding with existing ArangoDB volume."
        echo "-----------------------------------------------------------------------"
    fi
}

ensure_hosts_entries() {
  echo
  echo "[INFO] Checking /etc/hosts entries for Catalyst and Authelia..."

  local missing_hosts=()

  # Check Catalyst host
  if [ -n "$CATALYST_HOST" ] && ! grep -q "$CATALYST_HOST" /etc/hosts 2>/dev/null; then
    missing_hosts+=("$CATALYST_HOST")
  fi

  # Check Authelia host
  if [ -n "$AUTHELIA_DOMAIN" ] && ! grep -q "$AUTHELIA_DOMAIN" /etc/hosts 2>/dev/null; then
    missing_hosts+=("$AUTHELIA_DOMAIN")
  fi

  # Nothing missing → no prompt
  if [ "${#missing_hosts[@]}" -eq 0 ]; then
    echo "[OK] /etc/hosts already contains entries for:"
    [ -n "$CATALYST_HOST" ] && echo "     - $CATALYST_HOST"
    [ -n "$AUTHELIA_DOMAIN" ] && echo "     - $AUTHELIA_DOMAIN"
    return 0
  fi

  # Something is missing → show warning + prompt once
  echo "[WARN] /etc/hosts is missing entries for:"
  for h in "${missing_hosts[@]}"; do
    echo "       - $h"
  done

  echo
  read -r -p "[PROMPT] Add 127.0.0.1 entries for these hostnames to /etc/hosts? (y/n): " ans
if [[ ! "$ans" =~ ^[Yy]$ ]]; then
  echo "[SKIP] Not modifying /etc/hosts. You'll need to add these entries manually."
  return 0
fi

  # Append missing entries
  for h in "${missing_hosts[@]}"; do
    echo "127.0.0.1 $h" | sudo tee -a /etc/hosts >/dev/null \
      && echo "[OK] Added: 127.0.0.1 $h" \
      || echo "[ERROR] Failed to add: 127.0.0.1 $h (sudo/permissions issue?)"
  done
}

# ---------------------------
# 1. Defaults & CLI parsing
# ---------------------------

INSTALL_DIR="$PWD/catalyst-ir-stack"
CATALYST_ADDR="https://catalyst.localhost"
AUTHELIA_ADDR="https://authelia.localhost"
ADMIN_USER_SEED="admin:admin:admin@example.com"

usage() {
  cat <<USAGE
Usage: $0 [options]

Options:
  --install-dir DIR           Install directory (default: ./catalyst-ir-stack)
  --admin-seed user:pass:email
                              Admin seed for Authelia + Catalyst (default: admin:admin:admin@example.com)
  --catalyst-url URL          External URL for Catalyst (default: https://catalyst.localhost)
  --authelia-url URL          External URL for Authelia (default: https://authelia.localhost)
  -h, --help                  Show this help and exit

Examples:
  $0
  $0 --install-dir /opt/catalyst-ir --admin-seed alice:s3cret:alice@example.com
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --install-dir)
      [[ $# -ge 2 ]] || { echo "[ERROR] --install-dir requires a value"; exit 1; }
      INSTALL_DIR="$2"
      shift 2
      ;;
    --admin-seed)
      [[ $# -ge 2 ]] || { echo "[ERROR] --admin-seed requires a value"; exit 1; }
      ADMIN_USER_SEED="$2"
      shift 2
      ;;
    --catalyst-url)
      [[ $# -ge 2 ]] || { echo "[ERROR] --catalyst-url requires a value"; exit 1; }
      CATALYST_ADDR="$2"
      shift 2
      ;;
    --authelia-url)
      [[ $# -ge 2 ]] || { echo "[ERROR] --authelia-url requires a value"; exit 1; }
      AUTHELIA_ADDR="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "[WARN] Unknown option: $1"
      echo
      usage
      exit 1
      ;;
  esac
done

# ---------------------------
# 2. Preflight checks
# ---------------------------

# Require https:// for external URLs
if [[ "$CATALYST_ADDR" != https://* ]]; then
  echo "[ERROR] --catalyst-url must start with https:// (got: $CATALYST_ADDR)"
  exit 1
fi

if [[ "$AUTHELIA_ADDR" != https://* ]]; then
  echo "[ERROR] --authelia-url must start with https:// (got: $AUTHELIA_ADDR)"
  exit 1
fi

# Very simple format check for admin seed: user:password:email
if ! [[ "$ADMIN_USER_SEED" =~ ^[^:]+:[^:]+:[^:]+$ ]]; then
  echo "[ERROR] --admin-seed must be in the form user:password:email (got: $ADMIN_USER_SEED)"
  exit 1
fi

if ! command -v openssl >/dev/null 2>&1; then
  echo "[ERROR] OpenSSL is not installed or not on PATH."
  echo "Please install OpenSSL (openssl) and re-run this script."
  exit 1
fi

#echo "[OK] OpenSSL found: $(openssl version)"

if ! command -v docker >/dev/null 2>&1; then
  echo "[ERROR] Docker is not installed or not on PATH."
  echo "Please install Docker Desktop or the Docker engine, then re-run this script."
  exit 1
fi

DC=()        # array holding the chosen command
DC_STR=""    # human-readable string for logging

if docker compose version >/dev/null 2>&1; then
  DC=(docker compose)
  DC_STR="docker compose"
  echo "[OK] Using 'docker compose'"
elif command -v docker-compose >/dev/null 2>&1; then
  DC=(docker-compose)
  DC_STR="docker-compose"
  echo "[WARN] Using legacy 'docker-compose' binary."
  echo "      (You can update Docker later to get 'docker compose'.)"
else
  echo "[ERROR] Neither 'docker compose' nor 'docker-compose' is available."
  echo "Please install or update Docker so that one of them exists, then re-run."
  exit 1
fi

check_arango_volume

# ---------------------------
# 3. Show config & confirm
# ---------------------------

echo
echo "[INFO] Install directory:  $INSTALL_DIR"
echo "[INFO] Catalyst URL:       $CATALYST_ADDR"
echo "[INFO] Authelia URL:       $AUTHELIA_ADDR"
echo "[INFO] Admin user (seed):  $ADMIN_USER_SEED"
echo

read -r -p "Continue with these values? [y/N]: " yn
if [[ ! "$yn" =~ ^[Yy]$ ]]; then
  echo "[INFO] Aborting."
  exit 0
fi

# Safety: warn if INSTALL_DIR exists and is non-empty
if [[ -e "$INSTALL_DIR" && ! -d "$INSTALL_DIR" ]]; then
  echo "[ERROR] $INSTALL_DIR exists and is not a directory."
  exit 1
fi

if [[ -d "$INSTALL_DIR" && -n "$(ls -A "$INSTALL_DIR" 2>/dev/null || true)" ]]; then
  echo "[WARN] Install directory already exists and is not empty:"
  echo "       $INSTALL_DIR"
  read -r -p "Continue and potentially overwrite configs? [y/N]: " yn2
  if [[ ! "$yn2" =~ ^[Yy]$ ]]; then
    echo "[INFO] Aborting."
    exit 0
  fi
fi

echo "[INFO] Checking for port conflicts on 80 and 443 (if lsof is available)..."
check_port_in_use 80
check_port_in_use 443
echo

# ---------------------------
# 4. Create directory layout
# ---------------------------

mkdir -p "$INSTALL_DIR"/{authelia,nginx,nginx/certs}
cd "$INSTALL_DIR"

echo "[OK] Using structure under: $INSTALL_DIR"
echo "     - authelia/"
echo "     - nginx/"
echo "     - nginx/certs/"
echo

# ---------------------------
# 5. Generate secrets & certs
# ---------------------------

echo "[INFO] Generating secrets..."

SECRET="$(openssl rand -hex 32)"
ARANGO_ROOT_PASSWORD="$(openssl rand -hex 16)"
S3_PASSWORD="$(openssl rand -hex 32)"
AUTHELIA_JWT_SECRET="$(openssl rand -hex 32)"
AUTHELIA_HMAC_SECRET="$(openssl rand -hex 32)"
AUTHELIA_STORAGE_ENCRYPTION_KEY="$(openssl rand -hex 32)"
AUTHELIA_SESSION_SECRET="$(openssl rand -hex 32)"
OIDC_CLIENT_SECRET="$(openssl rand -hex 32)"
INITIAL_API_KEY="$(openssl rand -hex 64)"

echo "[OK] Secrets generated."

echo "[INFO] Writing .env file for docker-compose..."

cat > .env <<EOF
# Generated by setup_catalyst_stack.sh
# You can edit these and re-run: ${DC_STR} up -d

CATALYST_ADDR=${CATALYST_ADDR}
AUTHELIA_ADDR=${AUTHELIA_ADDR}

SECRET=${SECRET}
ARANGO_ROOT_PASSWORD=${ARANGO_ROOT_PASSWORD}
S3_PASSWORD=${S3_PASSWORD}

AUTHELIA_JWT_SECRET=${AUTHELIA_JWT_SECRET}
AUTHELIA_HMAC_SECRET=${AUTHELIA_HMAC_SECRET}
AUTHELIA_STORAGE_ENCRYPTION_KEY=${AUTHELIA_STORAGE_ENCRYPTION_KEY}
AUTHELIA_SESSION_SECRET=${AUTHELIA_SESSION_SECRET}

OIDC_CLIENT_SECRET=${OIDC_CLIENT_SECRET}
INITIAL_API_KEY=${INITIAL_API_KEY}
EOF

echo "[OK] .env file created."

# Self-signed cert for nginx TLS (dev-only)
CRT_PATH="nginx/certs/cert.pem"
KEY_PATH="nginx/certs/key.pem"

if [[ ! -f "$CRT_PATH" || ! -f "$KEY_PATH" ]]; then
  echo "[INFO] Generating self-signed TLS cert for nginx..."
  openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes \
    -keyout "$KEY_PATH" -out "$CRT_PATH" -subj "/CN=localhost"
  echo "[OK] Certs created at: $CRT_PATH, $KEY_PATH"
else
  echo "[INFO] Reusing existing TLS certs in nginx/certs/."
fi

# ---------------------------
# 6. Write docker-compose.yml
# ---------------------------

echo "[INFO] Writing docker-compose.yml..."

# NOTE: We use a *single-quoted* heredoc so Bash doesn't expand ${VAR}.
#       Docker Compose will substitute from .env at runtime.

cat > docker-compose.yml <<'EOF'
version: "3.7"

services:
  nginx:
    image: nginx:1.25-alpine
    restart: unless-stopped
    depends_on:
      - catalyst
      - authelia
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/certs:/etc/nginx/certs:ro
    networks:
      - catalyst-net

  catalyst:
    image: ghcr.io/securitybrewery/catalyst:v0.10.3
    restart: unless-stopped
    environment:
      SECRET: "${SECRET}"
      EXTERNAL_ADDRESS: "${CATALYST_ADDR}"
      OIDC_ISSUER: "http://authelia:9091"
      OIDC_AUTH_URL: "${AUTHELIA_ADDR}/api/oidc/authorization"
      OIDC_CLIENT_ID: "catalyst"
      OIDC_CLIENT_SECRET: "${OIDC_CLIENT_SECRET}"
      ARANGO_DB_HOST: "http://arangodb:8529"
      ARANGO_DB_USER: "root"
      ARANGO_DB_PASSWORD: "${ARANGO_ROOT_PASSWORD}"
      S3_PASSWORD: "${S3_PASSWORD}"
      AUTH_BLOCK_NEW: "false"
      AUTH_DEFAULT_ROLES: "analyst"
      AUTH_ADMIN_USERS: "admin"
      INITIAL_API_KEY: "${INITIAL_API_KEY}"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    depends_on:
      - arangodb
      - minio
      - authelia
    networks:
      - catalyst-net

  arangodb:
    image: arangodb/arangodb:3.8.1
    restart: unless-stopped
    environment:
      ARANGO_ROOT_PASSWORD: "${ARANGO_ROOT_PASSWORD}"
    volumes:
      - arangodb:/var/lib/arangodb3
    networks:
      - catalyst-net

  minio:
    image: minio/minio:latest
    restart: unless-stopped
    environment:
      MINIO_ROOT_USER: "minio"
      MINIO_ROOT_PASSWORD: "${S3_PASSWORD}"
    command: server /data
    volumes:
      - minio:/data
    networks:
      - catalyst-net

  authelia:
    image: authelia/authelia:4.37.5
    restart: unless-stopped
    environment:
      AUTHELIA_JWT_SECRET: "${AUTHELIA_JWT_SECRET}"
      AUTHELIA_IDENTITY_PROVIDERS_OIDC_ISSUER_PRIVATE_KEY_FILE: "/config/private.pem"
      AUTHELIA_IDENTITY_PROVIDERS_OIDC_HMAC_SECRET: "${AUTHELIA_HMAC_SECRET}"
      AUTHELIA_STORAGE_ENCRYPTION_KEY: "${AUTHELIA_STORAGE_ENCRYPTION_KEY}"
      AUTHELIA_SESSION_SECRET: "${AUTHELIA_SESSION_SECRET}"
    volumes:
      - ./authelia/configuration.yml:/config/configuration.yml
      - ./authelia/private.pem:/config/private.pem
      - ./authelia/users_database.yml:/config/users_database.yml
    networks:
      - catalyst-net

volumes:
  arangodb:
  minio:

networks:
  catalyst-net:
    name: catalyst-net
EOF

echo "[OK] docker-compose.yml written."

# ---------------------------
# 7. Generate Authelia files
# ---------------------------

echo "[INFO] Generating Authelia private key..."
openssl genrsa -out authelia/private.pem 4096

# Parse admin seed (user:password:email)
ADMIN_USERNAME="$(echo "$ADMIN_USER_SEED" | cut -d: -f1)"
ADMIN_PASSWORD="$(echo "$ADMIN_USER_SEED" | cut -d: -f2)"
ADMIN_EMAIL="$(echo "$ADMIN_USER_SEED" | cut -d: -f3)"

if [[ -z "$ADMIN_USERNAME" || -z "$ADMIN_PASSWORD" || -z "$ADMIN_EMAIL" ]]; then
  echo "[ERROR] ADMIN_USER_SEED must be in the format user:password:email"
  exit 1
fi

echo "[INFO] Creating Authelia users_database.yml..."

HASH_OUTPUT=$(docker run --rm authelia/authelia:4.37.5 authelia hash-password -- "$ADMIN_PASSWORD")
ADMIN_HASH=$(echo "$HASH_OUTPUT" | awk '/Digest:/{print $2}')

if [[ -z "$ADMIN_HASH" ]]; then
  echo "[ERROR] Failed to parse password hash from Authelia output."
  echo "Output was:"
  echo "$HASH_OUTPUT"
  exit 1
fi

cat > authelia/users_database.yml <<EOF
users:
  ${ADMIN_USERNAME}:
    displayname: "${ADMIN_USERNAME}"
    password: "${ADMIN_HASH}"
    email: "${ADMIN_EMAIL}"
EOF

echo "[OK] authelia/users_database.yml created."

# Derive Authelia cookie domain from AUTHELIA_ADDR (strip scheme, port, and trailing slash)
AUTHELIA_HOST="${AUTHELIA_ADDR#http://}"
AUTHELIA_HOST="${AUTHELIA_HOST#https://}"
AUTHELIA_HOST="${AUTHELIA_HOST%%:*}"   # drop :port if present
AUTHELIA_DOMAIN="${AUTHELIA_HOST%/}"   # drop trailing slash if present

CATALYST_HOST="${CATALYST_ADDR#http://}"
CATALYST_HOST="${CATALYST_HOST#https://}"
CATALYST_HOST="${CATALYST_HOST%%:*}"   # drop :port if present
CATALYST_HOST="${CATALYST_HOST%/}"     # drop trailing slash

if [[ -z "$AUTHELIA_DOMAIN" ]]; then
  echo "[ERROR] Failed to derive Authelia cookie domain from AUTHELIA_ADDR ($AUTHELIA_ADDR)"
  exit 1
fi

if [[ -z "$CATALYST_HOST" ]]; then
  echo "[ERROR] Failed to derive Catalyst cookie domain from CATALYST_HOST ($CATALYST_HOST)"
  exit 1
fi

ensure_hosts_entries

echo "[INFO] Writing authelia/configuration.yml..."

cat > authelia/configuration.yml <<EOF
server:
  host: 0.0.0.0
  port: 9091

log:
  format: text

authentication_backend:
  file:
    path: /config/users_database.yml

access_control:
  default_policy: one_factor

session:
  domain: "${AUTHELIA_DOMAIN}"

storage:
  local:
    path: /config/db.sqlite3

notifier:
  filesystem:
    filename: /config/notification.txt

identity_providers:
  oidc:
    cors:
      allowed_origins_from_client_redirect_uris: true
    clients:
      - id: "catalyst"
        description: "Catalyst IR UI"
        secret: "${OIDC_CLIENT_SECRET}"
        public: false
        authorization_policy: one_factor
        scopes: [ openid, email, profile ]
        redirect_uris:
          - "${CATALYST_ADDR}/auth/callback"
        userinfo_signing_algorithm: none
EOF

echo "[OK] authelia/configuration.yml created."

# ---------------------------
# 8. Generate nginx.conf
# ---------------------------

echo "[INFO] Writing nginx/nginx.conf..."

cat > nginx/nginx.conf <<EOF
user  nginx;
worker_processes  5;
error_log  /var/log/nginx/error.log;

events {
  worker_connections  4096;
}

http {
  include       mime.types;
  index         index.html index.htm;

  client_max_body_size 100M;
  client_body_timeout 300s;
  client_header_timeout 300s;

  log_format   main '\$remote_addr - \$remote_user [\$time_local]  \$status '
    '"\$request" \$body_bytes_sent "\$http_referer" '
    '"\$http_user_agent" "\$http_x_forwarded_for"';
  access_log   /var/log/nginx/access.log main;

  # Redirect all plain HTTP to HTTPS
  server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://\$host\$request_uri;
  }

  # Catalyst
  server {
    listen       443 ssl;
    server_name  "${CATALYST_HOST}";

    ssl_certificate     /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    client_max_body_size 0;
    proxy_buffering off;

    location / {
      resolver        127.0.0.11 valid=30s;
      proxy_pass      http://catalyst:8000;
    }

    location /wss {
      resolver        127.0.0.11 valid=30s;
      proxy_pass      http://catalyst:8000;

      proxy_http_version 1.1;
      proxy_set_header Upgrade \$http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_read_timeout 86400;
    }
  }

  # Authelia
  server {
    listen      443 ssl;
    server_name "${AUTHELIA_HOST}";

    ssl_certificate     /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    location / {
      resolver              127.0.0.11 valid=30s;
      proxy_pass            http://authelia:9091;
      proxy_set_header      Host \$host;
      proxy_set_header      X-Real-IP \$remote_addr;
      proxy_set_header      X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header      X-Forwarded-Proto https;
      proxy_set_header      X-Forwarded-Host \$http_host;
      proxy_set_header      X-Forwarded-Uri \$request_uri;
      proxy_set_header      X-Forwarded-Ssl on;
      proxy_http_version    1.1;
      proxy_set_header      Connection "";
    }
  }
}
EOF

echo "[OK] nginx/nginx.conf created."

# ---------------------------
# 9. Bring the stack up
# ---------------------------

echo
echo "[INFO] Starting Catalyst stack with: $DC_STR up -d"
"${DC[@]}" up -d

echo
echo "[INFO] Checking service status..."
RUNNING=$("${DC[@]}" ps --services --status running || true)

for s in nginx catalyst authelia arangodb minio; do
  if ! echo "$RUNNING" | grep -qx "$s"; then
    echo "[WARN] Service not reported as running yet: $s"
  fi
done

echo
echo "===================================================="
echo "Catalyst IR stack started (or is starting)."
echo
echo "Access Catalyst via browser at:"
echo "  ${CATALYST_ADDR}"
echo
echo "Access Authelia (login UI) at:"
echo "  ${AUTHELIA_ADDR}"
echo
echo "Admin seed user:"
echo "  Username: ${ADMIN_USERNAME}"
echo "  Password: ${ADMIN_PASSWORD}"
echo "  Email:    ${ADMIN_EMAIL}"
echo
echo "Initial API key for Catalyst:"
echo "  ${INITIAL_API_KEY}"
echo
echo "To check logs:"
echo "  cd \"$INSTALL_DIR\""
echo "  $DC_STR logs -f"
echo
echo "To stop the stack:"
echo "  $DC_STR down"
echo "===================================================="