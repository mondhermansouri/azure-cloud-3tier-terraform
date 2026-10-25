#!/usr/bin/env bash
# Bootstrap one-time : crée le backend distant Terraform (Azure Storage)
# et le Service Principal utilisé par GitHub Actions.
# Pré-requis : Azure CLI connecté (az login) sur l'abonnement cible.
set -euo pipefail

# --- Paramètres (à adapter) -----------------------------------------------
LOCATION="${LOCATION:-francecentral}"
RG_STATE="${RG_STATE:-rg-tfstate}"
SA_STATE="${SA_STATE:-sttfstateweb3t}"   # doit être globalement unique, 3-24 car. minuscules
CONTAINER="${CONTAINER:-tfstate}"
SP_NAME="${SP_NAME:-sp-web3t-github-actions}"

SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

echo ">> Création du resource group d'état : $RG_STATE"
az group create --name "$RG_STATE" --location "$LOCATION" 1>/dev/null

echo ">> Création du storage account : $SA_STATE"
az storage account create \
  --name "$SA_STATE" \
  --resource-group "$RG_STATE" \
  --location "$LOCATION" \
  --sku Standard_ZRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false 1>/dev/null

echo ">> Création du conteneur : $CONTAINER"
az storage container create \
  --name "$CONTAINER" \
  --account-name "$SA_STATE" \
  --auth-mode login 1>/dev/null

echo ">> Création du Service Principal : $SP_NAME (rôle Contributor sur l'abonnement)"
SP_JSON="$(az ad sp create-for-rbac \
  --name "$SP_NAME" \
  --role Contributor \
  --scopes "/subscriptions/$SUBSCRIPTION_ID")"

CLIENT_ID="$(echo "$SP_JSON" | grep -o '"appId": *"[^"]*"' | cut -d'"' -f4)"
CLIENT_SECRET="$(echo "$SP_JSON" | grep -o '"password": *"[^"]*"' | cut -d'"' -f4)"
TENANT_ID="$(echo "$SP_JSON" | grep -o '"tenant": *"[^"]*"' | cut -d'"' -f4)"

# Le SP doit aussi pouvoir gérer les secrets/role assignments (Key Vault Administrator,
# User Access Administrator) selon votre politique. Ajustez si nécessaire :
az role assignment create --assignee "$CLIENT_ID" \
  --role "User Access Administrator" \
  --scope "/subscriptions/$SUBSCRIPTION_ID" 1>/dev/null || true

cat <<EOF

==============================================================
Backend prêt. Renseignez ces secrets GitHub (Settings > Secrets > Actions) :

  ARM_CLIENT_ID        = $CLIENT_ID
  ARM_CLIENT_SECRET    = $CLIENT_SECRET
  ARM_TENANT_ID        = $TENANT_ID
  ARM_SUBSCRIPTION_ID  = $SUBSCRIPTION_ID

Backend (déjà référencé dans environments/<env>/backend.tfvars) :
  resource_group_name  = $RG_STATE
  storage_account_name = $SA_STATE
  container_name       = $CONTAINER
==============================================================
EOF
