#!/bin/bash

# Script to create Kubernetes secrets from secrets.env file
# Usage: ./create-secrets.sh

set -e

NAMESPACE="homelab"
SECRETS_FILE="secrets.env"

# Check if secrets.env exists
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Error: $SECRETS_FILE not found!"
    echo "Please copy secrets.env.example to secrets.env and fill in your passwords."
    exit 1
fi

# Source the secrets file
source "$SECRETS_FILE"

# Create namespace if it doesn't exist
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Create Pi-hole secret
if [ ! -z "$PIHOLE_WEB_PASSWORD" ]; then
    kubectl create secret generic pihole-secret \
        --from-literal=FTLCONF_webserver_api_password="$PIHOLE_WEB_PASSWORD" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✓ Created pihole-secret"
fi

# Create MSSQL secret
if [ ! -z "$MSSQL_SA_PASSWORD" ]; then
    kubectl create secret generic mssql-secret \
        --from-literal=MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✓ Created mssql-secret"
fi

# Create MySQL secret
if [ ! -z "$MYSQL_ROOT_PASSWORD" ] && [ ! -z "$MYSQL_PASSWORD" ]; then
    kubectl create secret generic mysql-secret \
        --from-literal=MYSQL_ROOT_PASSWORD="$MYSQL_ROOT_PASSWORD" \
        --from-literal=MYSQL_PASSWORD="$MYSQL_PASSWORD" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✓ Created mysql-secret"
fi

# Create PostgreSQL secret
if [ ! -z "$POSTGRES_PASSWORD" ]; then
    kubectl create secret generic pgsql-secret \
        --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    echo "✓ Created pgsql-secret"
fi

echo ""
echo "All secrets created successfully in namespace: $NAMESPACE"
echo "You can now deploy your services with: kubectl apply -f ."
