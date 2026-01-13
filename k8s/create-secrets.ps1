# PowerShell script to create Kubernetes secrets from secrets.env file
# Usage: .\create-secrets.ps1

$NAMESPACE = "homelab"
$SECRETS_FILE = "secrets.env"

# Check if secrets.env exists
if (-not (Test-Path $SECRETS_FILE)) {
    Write-Host "Error: $SECRETS_FILE not found!" -ForegroundColor Red
    Write-Host "Please copy secrets.env.example to secrets.env and fill in your passwords." -ForegroundColor Yellow
    exit 1
}

# Read secrets.env file
$secrets = @{}
Get-Content $SECRETS_FILE | ForEach-Object {
    if ($_ -match '^\s*([^#][^=]+)=(.*)$') {
        $key = $matches[1].Trim()
        $value = $matches[2].Trim()
        if ($value -and $value -ne '') {
            $secrets[$key] = $value
        }
    }
}

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f - | Out-Null

# Create Pi-hole secret
if ($secrets.ContainsKey("PIHOLE_WEB_PASSWORD")) {
    kubectl create secret generic pihole-secret `
        --from-literal=FTLCONF_webserver_api_password="$($secrets['PIHOLE_WEB_PASSWORD'])" `
        -n $NAMESPACE `
        --dry-run=client -o yaml | kubectl apply -f - | Out-Null
    Write-Host "✓ Created pihole-secret" -ForegroundColor Green
}

# Create MSSQL secret
if ($secrets.ContainsKey("MSSQL_SA_PASSWORD")) {
    kubectl create secret generic mssql-secret `
        --from-literal=MSSQL_SA_PASSWORD="$($secrets['MSSQL_SA_PASSWORD'])" `
        -n $NAMESPACE `
        --dry-run=client -o yaml | kubectl apply -f - | Out-Null
    Write-Host "✓ Created mssql-secret" -ForegroundColor Green
}

# Create MySQL secret
if ($secrets.ContainsKey("MYSQL_ROOT_PASSWORD") -and $secrets.ContainsKey("MYSQL_PASSWORD")) {
    kubectl create secret generic mysql-secret `
        --from-literal=MYSQL_ROOT_PASSWORD="$($secrets['MYSQL_ROOT_PASSWORD'])" `
        --from-literal=MYSQL_PASSWORD="$($secrets['MYSQL_PASSWORD'])" `
        -n $NAMESPACE `
        --dry-run=client -o yaml | kubectl apply -f - | Out-Null
    Write-Host "✓ Created mysql-secret" -ForegroundColor Green
}

# Create PostgreSQL secret
if ($secrets.ContainsKey("POSTGRES_PASSWORD")) {
    kubectl create secret generic pgsql-secret `
        --from-literal=POSTGRES_PASSWORD="$($secrets['POSTGRES_PASSWORD'])" `
        -n $NAMESPACE `
        --dry-run=client -o yaml | kubectl apply -f - | Out-Null
    Write-Host "✓ Created pgsql-secret" -ForegroundColor Green
}

Write-Host ""
Write-Host "All secrets created successfully in namespace: $NAMESPACE" -ForegroundColor Green
Write-Host "You can now deploy your services with: kubectl apply -f ." -ForegroundColor Cyan
