<# 
  Catalyst IR Stack Installer (PowerShell) — Sections 0–2
  - 0) Error handling + helper functions
  - 1) Defaults & CLI parsing
  - 2) Preflight checks (openssl/docker/compose) + Arango volume warning
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

Write-Host "=== Catalyst IR Stack Installer ===" -ForegroundColor Magenta

# ---------------------------
# 0. Simple error trap + helpers
# ---------------------------

function Write-Log {
    param (
        [string]$Message,
        [string]$Level = "INFO"
    )
    $Color = switch ($Level) {
        "INFO"  { "Cyan" }
        "WARN"  { "Yellow" }
        "ERROR" { "Red" }
        "OK"    { "Green" }
        Default { "White" }
    }
    Write-Host "$Level $Message" -ForegroundColor $Color
}

function On-Error {
    param([Parameter(Mandatory=$true)][System.Management.Automation.ErrorRecord]$Err)

    Write-Host ""
    Write-Host "[ERROR] Installation failed. See messages above for details."

    # Only show logs hint if these vars are already defined (parity with Bash)
    if ($script:ComposeStr -and $script:InstallDir) {
        Write-Host "[HINT] You can check container logs with:"
        Write-Host "       cd `"$script:InstallDir`" && $script:ComposeStr logs -f"
    }

    # Optional: show the underlying error message (useful on Windows)
    Write-Host ""
    Write-Log ("[DETAILS] " + $Err.Exception.Message) "ERROR"
}

function Test-CommandExists {
    param([Parameter(Mandatory=$true)][string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

# Optional: warn if common ports are already in use
function Check-PortInUse {
    param([Parameter(Mandatory=$true)][int]$Port)

    # Rough equivalent to "if lsof exists" → on Windows we check if Get-NetTCPConnection exists
    if (Test-CommandExists "Get-NetTCPConnection") {
        $listener = Get-NetTCPConnection -State Listen -LocalPort $Port -ErrorAction SilentlyContinue |
                    Select-Object -First 1
        if ($listener) {
            Write-Log "Port $Port appears to be in use on this host." "WARN"
            Write-Log "       The nginx container may fail to bind to port $Port." "WARN"
        }
    }
}

function Check-ArangoVolume {
    $ArangoVolName = "catalyst-ir-stack_arangodb"  # change if needed

    # Safe check: docker volume ls never errors for missing volumes
    $existing = & docker volume ls -q 2>$null | Where-Object { $_ -eq $ArangoVolName }

    if ($existing) {
        Write-Host "-----------------------------------------------------------------------"
        Write-Log "[WARNING] Existing ArangoDB Docker volume detected: $ArangoVolName" "WARN"
        Write-Host ""
        Write-Log "ArangoDB is already initialized and WILL IGNORE any new root password." "WARN"
        Write-Log "If .env contains a different ARANGO_ROOT_PASSWORD than the one used" "WARN"
        Write-Log "when this volume was first created, Catalyst will fail to authenticate." "WARN"
        Write-Host ""
        Write-Host "Options:"
        Write-Host "  1) Delete the volume for a clean install:"
        Write-Host "         docker volume rm $ArangoVolName"
        Write-Host ""
        Write-Host "  2) Keep the existing volume but ensure .env uses the SAME password."
        Write-Host ""

        if ($script:Force) {
            Write-Host "[FORCE] Proceeding with existing ArangoDB volume (no prompt)."
            Write-Host "-----------------------------------------------------------------------"
            return
        }

        $resp = Read-Host "Do you want to continue using the existing ArangoDB volume? (yes/no)"
        if ($resp -ne "yes") {
            Write-Host "[ABORTED] Delete the volume or fix .env before rerunning the installer."
            exit 1
        }

        Write-Log "Proceeding with existing ArangoDB volume." "INFO"
        Write-Host "-----------------------------------------------------------------------"
    }
}

function Usage {
@"
Usage: setup_catalyst_stack.ps1 [options]

Options:
  --install-dir DIR           Install directory (default: ./catalyst-ir-stack)
  --admin-seed user:pass:email
                              Admin seed for Authelia + Catalyst
                              (default: admin:admin:admin@example.com)
  --catalyst-url URL          External URL for Catalyst
                              (default: https://catalyst.localhost)
  --authelia-url URL          External URL for Authelia
                              (default: https://authelia.localhost)
  --force                     Run non-interactively.
                              Skips all prompts and assumes "yes" for actions,
                              except for hosts file modification which will only
                              occur if running as Administrator.
  -h, --help                  Show this help and exit

Examples:
  .\setup_catalyst_stack.ps1
  .\setup_catalyst_stack.ps1 --force
  .\setup_catalyst_stack.ps1 --install-dir C:\tools\catalyst-ir `
                             --admin-seed alice:s3cret:alice@example.com `
                             --force
"@
}

# We'll keep "manual parsing" to mimic Bash behavior (unknown option => warn + usage + exit 1)
function Parse-Args {
    param([string[]]$Argv)

    # ---------------------------
    # 1. Defaults
    # ---------------------------
    $script:InstallDir    = Join-Path (Get-Location) "catalyst-ir-stack"
    $script:CatalystAddr  = "https://catalyst.localhost"
    $script:AutheliaAddr  = "https://authelia.localhost"
    $script:AdminUserSeed = "admin:admin:admin@example.com"
    $script:Force = $false

    for ($i = 0; $i -lt $Argv.Count; $i++) {
        $a = $Argv[$i]

        switch ($a) {
            "--install-dir" {
                if ($i + 1 -ge $Argv.Count) { Write-Log "[ERROR] --install-dir requires a value" "ERROR"; exit 1 }
                $script:InstallDir = $Argv[$i + 1]
                $i++
            }
            "--admin-seed" {
                if ($i + 1 -ge $Argv.Count) { Write-Log "[ERROR] --admin-seed requires a value" "ERROR"; exit 1 }
                $script:AdminUserSeed = $Argv[$i + 1]
                $i++
            }
            "--catalyst-url" {
                if ($i + 1 -ge $Argv.Count) { Write-Log "[ERROR] --catalyst-url requires a value" "ERROR"; exit 1 }
                $script:CatalystAddr = $Argv[$i + 1]
                $i++
            }
            "--authelia-url" {
                if ($i + 1 -ge $Argv.Count) { Write-Log "[ERROR] --authelia-url requires a value" "ERROR"; exit 1 }
                $script:AutheliaAddr = $Argv[$i + 1]
                $i++
            }
            "--force" {
                $script:Force = $true
            }
            "-h" { Write-Host (Usage); exit 0 }
            "--help" { Write-Host (Usage); exit 0 }
            default {
                Write-Log "[WARN] Unknown option: $a" "WARN"
                Write-Host ""
                Write-Host (Usage)
                exit 1
            }
        }
    }
}

# ---------------------------
# 2. Preflight checks
# ---------------------------

function Preflight-Checks {
    # Require https:// for external URLs
    if (-not $script:CatalystAddr.StartsWith("https://")) {
        Write-Log "--catalyst-url must start with https:// (got: $script:CatalystAddr)" "ERROR"
        exit 1
    }
    if (-not $script:AutheliaAddr.StartsWith("https://")) {
        Write-Log "--authelia-url must start with https:// (got: $script:AutheliaAddr)" "ERROR"
        exit 1
    }

    # Simple format check for admin seed: user:password:email
    if ($script:AdminUserSeed -notmatch '^[^:]+:[^:]+:[^:]+$') {
        Write-Log "--admin-seed must be in the form user:password:email (got: $script:AdminUserSeed)" "ERROR"
        exit 1
    }

    if (-not (Test-CommandExists "openssl")) {
        Write-Log "OpenSSL is not installed or not on PATH." "ERROR"
        Write-Host "Please install OpenSSL (openssl) and re-run this script."
        exit 1
    }

    if (-not (Test-CommandExists "docker")) {
        Write-Log "Docker is not installed or not on PATH." "ERROR"
        Write-Host "Please install Docker Desktop (Linux containers) and re-run this script."
        exit 1
    }

    # Detect docker compose vs docker-compose
    $script:ComposeCmd = $null
    $script:ComposeStr = ""

    # Try: docker compose version
    $null = & docker compose version 2>$null
    if ($LASTEXITCODE -eq 0) {
        $script:ComposeCmd = @("docker","compose")
        $script:ComposeStr = "docker compose"
        Write-Log "Using 'docker compose'" "OK"
    }
    else {
        # Try: docker-compose version
        if (Test-CommandExists "docker-compose") {
            $null = & docker-compose version 2>$null
            if ($LASTEXITCODE -eq 0) {
                $script:ComposeCmd = @("docker-compose")
                $script:ComposeStr = "docker-compose"
                Write-Log "[WARN] Using legacy 'docker-compose' binary." "WARN"
                Write-Host "      (You can update Docker later to get 'docker compose'.)"
            }
            else {
                Write-Log " [ERROR] Neither 'docker compose' nor 'docker-compose' is available." "ERROR"
                Write-Host "Please install or update Docker so that one of them exists, then re-run."
                exit 1
            }
        }
        else {
            Write-Log "[ERROR] Neither 'docker compose' nor 'docker-compose' is available." "ERROR"
            Write-Host "Please install or update Docker so that one of them exists, then re-run."
            exit 1
        }
    }

    Check-ArangoVolume
}

# ---------------------------
# 3. Show config & confirm
# ---------------------------

function Confirm-YesNo {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Prompt,

        # Optional override; if omitted we use the global --force flag
        [bool]$Force = $script:Force
    )

    if ($Force) {
        Write-Host "[FORCE] $Prompt -> yes"
        return $true
    }

    $ans = Read-Host $Prompt
    return ($ans -match '^[Yy]$')
}

function Section3-ShowConfigAndConfirm {

    Write-Host ""
    Write-Log "Install directory:  $InstallDir" "INFO"
    Write-Log "Catalyst URL:       $CatalystAddr" "INFO"
    Write-Log "Authelia URL:       $AutheliaAddr" "INFO"
    Write-Log "Admin user (seed):  $AdminUserSeed" "INFO"
    Write-Host ""

    $ok = Confirm-YesNo -Prompt "Continue with these values? [y/N]"
    if (-not $ok) {
        Write-Log "Aborting." "INFO"
        exit 0
    }

    # Safety: warn if INSTALL_DIR exists and is not a directory
    if (Test-Path $script:InstallDir) {
        $item = Get-Item $script:InstallDir -ErrorAction Stop
        if (-not $item.PSIsContainer) {
            Write-Log "[ERROR] $script:InstallDir exists and is not a directory." "ERROR"
            exit 1
        }
    }

    # If directory exists and is non-empty → warn + prompt
    if (Test-Path $script:InstallDir) {
        $hasAny = Get-ChildItem -LiteralPath $script:InstallDir -Force -ErrorAction SilentlyContinue |
                  Select-Object -First 1

        if ($hasAny) {
            Write-Log "[WARN] Install directory already exists and is not empty:" "WARN"
            Write-Host "       $script:InstallDir"

            $ok2 = Confirm-YesNo -Prompt "Continue and potentially overwrite configs? [y/N]"
            if (-not $ok2) {
                Write-Log "Aborting." "INFO"
                exit 0
            }
        }
    }

    Write-Log "Checking for port conflicts on 80 and 443..." "INFO"
    Check-PortInUse -Port 80
    Check-PortInUse -Port 443
    Write-Host ""
}

# ---------------------------
# 4. Create directory layout
# ---------------------------

function Section4-CreateDirectoryLayout {

    # Create:
    #   $InstallDir\
    #     authelia\
    #     nginx\
    #     nginx\certs\
    New-Item -ItemType Directory -Force -Path $script:InstallDir | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:InstallDir "authelia") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:InstallDir "nginx") | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $script:InstallDir "nginx\certs") | Out-Null

    Set-Location -LiteralPath $script:InstallDir

    Write-Log "Using structure under: $script:InstallDir" "OK"
    Write-Log "     - authelia/" "OK"
    Write-Log "     - nginx/" "OK"
    Write-Log "     - nginx/certs/" "OK"
    Write-Host ""
}

# ---------------------------
# 5. Generate secrets & certs
# ---------------------------

function New-RandomHex {
    <#
      Uses OpenSSL to generate cryptographically-secure random hex.
      Example: openssl rand -hex 32
    #>
    param([Parameter(Mandatory=$true)][int]$Bytes)

    $out = & openssl rand -hex $Bytes 2>$null
    if ($LASTEXITCODE -ne 0 -or -not $out) {
        throw "OpenSSL failed generating random hex ($Bytes bytes)."
    }
    return ($out.Trim())
}

function Write-TextFileNoBom {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content
    )

    # Always resolve to a full filesystem path
    $fullPath = [System.IO.Path]::GetFullPath($Path)

    # Ensure parent directory exists
    $parent = [System.IO.Path]::GetDirectoryName($fullPath)
    if ($parent -and -not (Test-Path $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($fullPath, $Content, $utf8NoBom)
}

function Section5-GenerateSecretsAndCerts {

    Write-Log "Generating secrets." ""

    # Store secrets in script scope so later sections can use them
    $script:SECRET                           = New-RandomHex -Bytes 32
    $script:ARANGO_ROOT_PASSWORD             = New-RandomHex -Bytes 16
    $script:S3_PASSWORD                      = New-RandomHex -Bytes 32
    $script:AUTHELIA_JWT_SECRET              = New-RandomHex -Bytes 32
    $script:AUTHELIA_HMAC_SECRET             = New-RandomHex -Bytes 32
    $script:AUTHELIA_STORAGE_ENCRYPTION_KEY  = New-RandomHex -Bytes 32
    $script:AUTHELIA_SESSION_SECRET          = New-RandomHex -Bytes 32
    $script:OIDC_CLIENT_SECRET               = New-RandomHex -Bytes 32
    $script:INITIAL_API_KEY                  = New-RandomHex -Bytes 64

    Write-Host ""
    Write-Log "Secrets generated." "OK"
    Write-Host ""

    Write-Log "Writing .env file for docker-compose." ""
    Write-Host ""

    # Match Bash .env contents closely
    $envContent = @"
# Generated by setup_catalyst_stack.ps1
# You can edit these and re-run: $($script:ComposeStr) up -d

CATALYST_ADDR=$($script:CatalystAddr)
AUTHELIA_ADDR=$($script:AutheliaAddr)

SECRET=$($script:SECRET)
ARANGO_ROOT_PASSWORD=$($script:ARANGO_ROOT_PASSWORD)
S3_PASSWORD=$($script:S3_PASSWORD)

AUTHELIA_JWT_SECRET=$($script:AUTHELIA_JWT_SECRET)
AUTHELIA_HMAC_SECRET=$($script:AUTHELIA_HMAC_SECRET)
AUTHELIA_STORAGE_ENCRYPTION_KEY=$($script:AUTHELIA_STORAGE_ENCRYPTION_KEY)
AUTHELIA_SESSION_SECRET=$($script:AUTHELIA_SESSION_SECRET)

OIDC_CLIENT_SECRET=$($script:OIDC_CLIENT_SECRET)
INITIAL_API_KEY=$($script:INITIAL_API_KEY)
"@

$envPath = Join-Path $script:InstallDir ".env"
Write-TextFileNoBom -Path $envPath -Content $envContent

if (-not (Test-Path -LiteralPath $envPath)) {
    throw ".env was not created at: $envPath"
}

try { attrib -h -s $envPath 2>$null | Out-Null } catch {}

Write-Log ".env file created" "OK"
Write-Host ""

    # Self-signed cert for nginx TLS (dev-only)
$crtPath = Join-Path $script:InstallDir "nginx\certs\cert.pem"
$keyPath = Join-Path $script:InstallDir "nginx\certs\key.pem"

if (-not (Test-Path -LiteralPath $crtPath) -or -not (Test-Path -LiteralPath $keyPath)) {
    Write-Log "Generating self-signed TLS cert for nginx." 
    Write-Host ""

    # Run through cmd.exe to avoid PowerShell treating OpenSSL stderr progress as a terminating error
    $cmd = "openssl req -x509 -newkey rsa:4096 -sha256 -days 3650 -nodes " +
           "-keyout `"$keyPath`" -out `"$crtPath`" -subj `"/CN=localhost`""

    cmd.exe /c $cmd | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL failed generating self-signed TLS certificate (exit code $LASTEXITCODE)."
    }

    if (-not (Test-Path -LiteralPath $crtPath) -or -not (Test-Path -LiteralPath $keyPath)) {
        throw "OpenSSL reported success but cert/key files were not found at expected paths."
    }

    Write-Log "Certs created at: $crtPath, $keyPath" "OK"
    Write-Host ""
}
else {
    Write-Log "Reusing existing TLS certs in nginx/certs/." "INFO"
    Write-Host ""
}
}

# ---------------------------
# 6. Write docker-compose.yml
# ---------------------------

function Section6-WriteDockerCompose {

    Write-Log "Writing docker-compose.yml." ""
    Write-Host ""

    # Single-quoted here-string prevents PowerShell from expanding anything inside,
    # so ${VAR} stays literal for Docker Compose to substitute from .env at runtime.
    $composeContent = @'

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
'@

    $composePath = Join-Path $script:InstallDir "docker-compose.yml"
    Write-TextFileNoBom -Path $composePath -Content $composeContent

    if (-not (Test-Path -LiteralPath $composePath)) {
        throw "docker-compose.yml was not created at: $composePath"
    }

    Write-Log "docker-compose.yml written." "OK"
    Write-Host ""
}

# ---------------------------
# 7. Generate Authelia files
# ---------------------------

function Get-HostFromUrl {
    param([Parameter(Mandatory=$true)][string]$Url)

    try {
        $u = [Uri]$Url
        return $u.Host
    } catch {
        throw "Invalid URL provided: $Url"
    }
}

function Ensure-HostsEntries {
    param(
        [Parameter(Mandatory=$true)][string]$CatalystHost,
        [Parameter(Mandatory=$true)][string]$AutheliaHost
    )

    Write-Host ""
    Write-Log "Checking hosts file entries for Catalyst and Authelia." ""
    Write-Host ""

    # Check for Admin privileges
    $IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

    $hostsPath = Join-Path $env:SystemRoot "System32\drivers\etc\hosts"
    $missing = New-Object System.Collections.Generic.List[string]

    $hostsText = ""
    if (Test-Path -LiteralPath $hostsPath) {
        $hostsText = Get-Content -LiteralPath $hostsPath -Raw -ErrorAction SilentlyContinue
    }

    if ($CatalystHost -and ($hostsText -notmatch [Regex]::Escape($CatalystHost))) {
        $missing.Add($CatalystHost)
    }
    if ($AutheliaHost -and ($hostsText -notmatch [Regex]::Escape($AutheliaHost))) {
        $missing.Add($AutheliaHost)
    }

    if ($missing.Count -eq 0) {
        Write-Log "hosts file already contains entries for:" "OK"
        if ($CatalystHost) { Write-Log "     - $CatalystHost" "INFO" }
        if ($AutheliaHost) { Write-Log "     - $AutheliaHost" "INFO" }
        return
    }

    Write-Log "[WARN] hosts file is missing entries for:" "WARN"
    foreach ($h in $missing) { Write-Log "       - $h" "WARN"}

    # --force behavior: no prompt; only proceed if admin
    if ($script:Force) {
        if (-not ($IsAdmin)) {
            Write-Log "[WARN] --force enabled but not running as Administrator. Skipping hosts file modification." "WARN"
            Write-Host "       Add these manually (as admin) to: $hostsPath"
            return
        }

        Write-Host "[FORCE] Running as Administrator. Adding missing hosts entries (no prompt)."
    }
    else {
        Write-Host ""
        $ans = Read-Host "[PROMPT] Add 127.0.0.1 entries for these hostnames to hosts file? (y/n)"
        if ($ans -notmatch '^[Yy]$') {
            Write-Host "[SKIP] Not modifying hosts file. You'll need to add these entries manually."
            return
        }
    }

    foreach ($h in $missing) {
        try {
            Add-Content -LiteralPath $hostsPath -Value "127.0.0.1 $h" -ErrorAction Stop
            Write-Log "Added: 127.0.0.1 $h" "OK"
        }
        catch {
            Write-Log "[ERROR] Failed to add: 127.0.0.1 $h (admin/permissions issue?)" "ERROR"
        }
    }
}

function New-AutheliaPrivateKeyWithAlpine {
    param(
        [Parameter(Mandatory=$true)][string]$KeyPath
    )

    Write-Log "Generating Authelia private key (Alpine OpenSSL)." ""
    Write-Host ""

    $parent = Split-Path -Parent $KeyPath
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }

    # Always generate inside a Linux container to avoid CRLF/BOM/encoding issues on Windows
    $hostDir = [System.IO.Path]::GetFullPath($parent)

    # Remove old key if present (avoid "valid but wrong format" surprises)
    if (Test-Path -LiteralPath $KeyPath) {
        Remove-Item -LiteralPath $KeyPath -Force -ErrorAction SilentlyContinue
    }

    & docker run --rm `
        -v "${hostDir}:/out" `
        alpine:latest `
        sh -lc "apk add --no-cache openssl >/dev/null 2>&1 && openssl genrsa -out /out/private.pem 4096" | Out-Null

    if ($LASTEXITCODE -ne 0) {
        throw "Failed generating Authelia private key using Alpine OpenSSL."
    }

    if (-not (Test-Path -LiteralPath $KeyPath)) {
        throw "Key generation reported success but file not found: $KeyPath"
    }

    Write-Log "Authelia private key created at: $KeyPath" "OK"
    Write-Host ""
}

function Section7-GenerateAutheliaFiles {

    # Paths
    $autheliaDir = Join-Path $script:InstallDir "authelia"
    $privateKeyPath = Join-Path $autheliaDir "private.pem"
    $usersDbPath = Join-Path $autheliaDir "users_database.yml"
    $autheliaConfigPath = Join-Path $autheliaDir "configuration.yml"

    New-AutheliaPrivateKeyWithAlpine -KeyPath $privateKeyPath

    # Parse admin seed: user:password:email
    $parts = $script:AdminUserSeed.Split(":", 3)
    if ($parts.Count -ne 3 -or -not $parts[0] -or -not $parts[1] -or -not $parts[2]) {
        throw "ADMIN_USER_SEED must be in the format user:password:email"
    }

    $script:AdminUsername = $parts[0]
    $script:AdminPassword = $parts[1]
    $script:AdminEmail    = $parts[2]

    Write-Log "Creating Authelia users_database.yml." ""
    Write-Host ""

    # Hash password via Authelia container (same as Bash)
    # docker run --rm authelia/authelia:4.37.5 authelia hash-password -- "<pass>"
    $hashOutput = & docker run --rm authelia/authelia:4.37.5 authelia hash-password -- $script:AdminPassword 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to hash password with Authelia container. Output: $hashOutput"
    }

    # Parse "Digest: <hash>"
    $m = [Regex]::Match($hashOutput, 'Digest:\s*(\S+)')
    if (-not $m.Success) {
        throw "Failed to parse password hash from Authelia output. Output: $hashOutput"
    }
    $adminHash = $m.Groups[1].Value

    $usersDb = @"
users:
  $($script:AdminUsername):
    displayname: "$($script:AdminUsername)"
    password: "$adminHash"
    email: "$($script:AdminEmail)"
"@

    Write-TextFileNoBom -Path $usersDbPath -Content $usersDb
    if (-not (Test-Path -LiteralPath $usersDbPath)) {
        throw "Failed to create: $usersDbPath"
    }
    Write-Log "authelia/users_database.yml created." "OK"

    # Derive domains/hosts from URLs (Bash stripped scheme/port/trailing slash)
    $script:AutheliaHost = Get-HostFromUrl -Url $script:AutheliaAddr
    $script:CatalystHost = Get-HostFromUrl -Url $script:CatalystAddr

    if (-not $script:AutheliaHost) { throw "Failed to derive Authelia host from AUTHELIA_ADDR ($script:AutheliaAddr)" }
    if (-not $script:CatalystHost) { throw "Failed to derive Catalyst host from CATALYST_ADDR ($script:CatalystAddr)" }

    # In your Bash, AUTHELIA_DOMAIN = AUTHELIA_HOST (no port). We'll match that.
    $script:AutheliaDomain = $script:AutheliaHost

    Ensure-HostsEntries -CatalystHost $script:CatalystHost -AutheliaHost $script:AutheliaHost
    Write-Host ""

    Write-Log "Writing authelia/configuration.yml." ""
    Write-Host ""

    $autheliaConfig = @"
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
  domain: "$($script:AutheliaDomain)"

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
        secret: "$($script:OIDC_CLIENT_SECRET)"
        public: false
        authorization_policy: one_factor
        scopes: [ openid, email, profile ]
        redirect_uris:
          - "$($script:CatalystAddr)/auth/callback"
        userinfo_signing_algorithm: none
"@

    Write-TextFileNoBom -Path $autheliaConfigPath -Content $autheliaConfig
    if (-not (Test-Path -LiteralPath $autheliaConfigPath)) {
        throw "Failed to create: $autheliaConfigPath"
    }

    Write-Log "authelia/configuration.yml created." "OK"
    Write-Host
}

# ---------------------------
# 8. Generate nginx.conf
# ---------------------------

function Section8-WriteNginxConf {

    Write-Log "Writing nginx/nginx.conf." ""
    Write-Host ""

    $nginxPath = Join-Path $script:InstallDir "nginx\nginx.conf"

    # NOTE: Single-quoted here-string prevents PowerShell from expanding $variables.
    # We build it with -f so we can safely insert the two hostnames.
    $tmpl = @'
user  nginx;
worker_processes  5;
error_log  /var/log/nginx/error.log;

events {{
  worker_connections  4096;
}}

http {{
  include       mime.types;
  index         index.html index.htm;

  client_max_body_size 100M;
  client_body_timeout 300s;
  client_header_timeout 300s;

  log_format   main '$remote_addr - $remote_user [$time_local]  $status '
    '"$request" $body_bytes_sent "$http_referer" '
    '"$http_user_agent" "$http_x_forwarded_for"';
  access_log   /var/log/nginx/access.log main;

  # Redirect all plain HTTP to HTTPS
  server {{
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name _;
    return 301 https://$host$request_uri;
  }}

  # Catalyst
  server {{
    listen       443 ssl;
    server_name  "{0}";

    ssl_certificate     /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;
    ssl_protocols       TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers         HIGH:!aNULL:!MD5;

    client_max_body_size 0;
    proxy_buffering off;

    location / {{
      resolver        127.0.0.11 valid=30s;
      proxy_pass      http://catalyst:8000;
    }}

    location /wss {{
      resolver        127.0.0.11 valid=30s;
      proxy_pass      http://catalyst:8000;

      proxy_http_version 1.1;
      proxy_set_header Upgrade $http_upgrade;
      proxy_set_header Connection "upgrade";
      proxy_read_timeout 86400;
    }}
  }}

  # Authelia
  server {{
    listen      443 ssl;
    server_name "{1}";

    ssl_certificate     /etc/nginx/certs/cert.pem;
    ssl_certificate_key /etc/nginx/certs/key.pem;

    location / {{
      resolver              127.0.0.11 valid=30s;
      proxy_pass            http://authelia:9091;
      proxy_set_header      Host $host;
      proxy_set_header      X-Real-IP $remote_addr;
      proxy_set_header      X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header      X-Forwarded-Proto https;
      proxy_set_header      X-Forwarded-Host $http_host;
      proxy_set_header      X-Forwarded-Uri $request_uri;
      proxy_set_header      X-Forwarded-Ssl on;
      proxy_http_version    1.1;
      proxy_set_header      Connection "";
    }}
  }}
}}
'@

    if (-not $script:CatalystHost -or -not $script:AutheliaHost) {
        throw "CatalystHost/AutheliaHost not set. Step 7 must run before Step 8."
    }

    $content = $tmpl -f $script:CatalystHost, $script:AutheliaHost

    Write-TextFileNoBom -Path $nginxPath -Content $content

    if (-not (Test-Path -LiteralPath $nginxPath)) {
        throw "Failed to create: $nginxPath"
    }

    Write-Log "nginx/nginx.conf created." "OK"
}

# ---------------------------
# 9. Bring the stack up
# ---------------------------

function Invoke-Compose {
    param(
        [Parameter(Mandatory=$true)][string[]]$Args
    )

    if (-not $script:ComposeCmd -or -not $script:ComposeCmd[0]) {
        throw "Compose command not initialized. Step 2 must run first."
    }

    # $script:ComposeCmd is either @("docker","compose") or @("docker-compose")
    if ($script:ComposeCmd.Count -eq 2) {
        & $script:ComposeCmd[0] $script:ComposeCmd[1] @Args
    } else {
        & $script:ComposeCmd[0] @Args
    }
}

function Section9-StartStackAndSummarize {

    Write-Host ""
    Write-Log "Starting Catalyst stack with: $($script:ComposeStr) up -d" "INFO"

    Invoke-Compose -Args @("up", "-d")

    Write-Host ""
    Write-Log "Checking service status." "INFO"

    # Get running services list (like: docker compose ps --services --status running)
    $runningRaw = Invoke-Compose -Args @("ps", "--services", "--status", "running") 2>$null
    $running = @()
    if ($runningRaw) {
        $running = $runningRaw -split "`r?`n" | Where-Object { $_ -and $_.Trim() -ne "" }
    }

    foreach ($s in @("nginx","catalyst","authelia","arangodb","minio")) {
        if ($running -notcontains $s) {
            Write-Log "[WARN] Service not reported as running yet: $s" "WARN"
        }
    }

    Write-Host ""
    Write-Host "====================================================" -ForegroundColor Green
    Write-Host "Catalyst IR stack started (or is starting)." -ForegroundColor Green
    Write-Host ""
    Write-Host "Access Catalyst via browser at:"
    Write-Log "  $($script:CatalystAddr)" "INFO"
    Write-Host ""
    Write-Host "Access Authelia (login UI) at:"
    Write-Log "  $($script:AutheliaAddr)" "INFO"
    Write-Host ""
    Write-Host "Admin seed user:"
    Write-Host "  Username: $($script:AdminUsername)" -ForegroundColor Green
    Write-Host "  Password: $($script:AdminPassword)" -ForegroundColor Green
    Write-Host "  Email:    $($script:AdminEmail)" -ForegroundColor Green
    Write-Host ""
    Write-Host "Initial API key for Catalyst:"
    Write-Host "  $($script:INITIAL_API_KEY)" -ForegroundColor Green
    Write-Host ""
    Write-Host "To check logs:"
    Write-Log "  cd `"$($script:InstallDir)`"" "INFO"
    Write-Log "  $($script:ComposeStr) logs -f" "INFO"
    Write-Host ""
    Write-Host "To stop the stack:"
    Write-Log "  $($script:ComposeStr) down" "INFO"
    Write-Host "====================================================" -ForegroundColor Green
}

# ---------------------------
#            MAIN
# ---------------------------

try {

    # Sections 0-2
    Parse-Args -Argv $args
    Preflight-Checks

    # Section 3
    Section3-ShowConfigAndConfirm

    # Section 4
    Section4-CreateDirectoryLayout

    # Section 5
    Section5-GenerateSecretsAndCerts

    # Section 6
    Section6-WriteDockerCompose

    # Section 7
    Section7-GenerateAutheliaFiles

    # Section 8
    Section8-WriteNginxConf

    # Section 9
    Section9-StartStackAndSummarize
}
catch {
    On-Error -Err $_
    exit 1
}
