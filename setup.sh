#!/usr/bin/env bash
set -euo pipefail

# --- 1. The author's CURRENT values ---
TFVARS=bootstrap/terraform.tfvars
OLD_ACCOUNT=$(grep -E '^account_id[[:space:]]*='  "$TFVARS" | cut -d'"' -f2)
OLD_REGION=$(grep -E  '^region[[:space:]]*='      "$TFVARS" | cut -d'"' -f2)
OLD_DOMAIN=$(grep -E  '^domain[[:space:]]*='      "$TFVARS" | cut -d'"' -f2)
OLD_REPO=$(grep -E    '^github_repo[[:space:]]*=' "$TFVARS" | cut -d'"' -f2)

# --- 2. Ask the porter for their 4 values ---
read -rp "AWS account ID [$OLD_ACCOUNT]: " ACCOUNT_ID
ACCOUNT_ID="${ACCOUNT_ID:-$OLD_ACCOUNT}"

read -rp "AWS region [$OLD_REGION]: " REGION
REGION="${REGION:-$OLD_REGION}"

read -rp "Domain [$OLD_DOMAIN]: " DOMAIN
DOMAIN="${DOMAIN:-$OLD_DOMAIN}"

read -rp "GitHub repo (owner/repo) [$OLD_REPO]: " REPO
REPO="${REPO:-$OLD_REPO}"

# --- 3. Files that contain those literals ---
FILES=(
  bootstrap/terraform.tfvars
  infra/terraform.tfvars
  bootstrap/backend.tf.disabled
  infra/backend.tf
  dockerfile
)

# --- 4. Swap old -> new in each file ---
for f in "${FILES[@]}"; do
  sed -i.bak \
    -e "s|${OLD_ACCOUNT}|${ACCOUNT_ID}|g" \
    -e "s|${OLD_REGION}|${REGION}|g" \
    -e "s|${OLD_DOMAIN}|${DOMAIN}|g" \
    -e "s|${OLD_REPO}|${REPO}|g" \
    "$f"
  rm "${f}.bak"
done

# --- 5. Set the GitHub Actions variables (derived from the same inputs) ---
ECR_REPO="${ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/memos"
gh variable set AWS_ACCOUNT_ID --body "$ACCOUNT_ID" --repo "$REPO"
gh variable set AWS_REGION     --body "$REGION"     --repo "$REPO"
gh variable set ECR_REPO       --body "$ECR_REPO"   --repo "$REPO"
gh variable set APP_DOMAIN     --body "$DOMAIN"     --repo "$REPO"

echo "Done. Review the changed files, then run terraform init/apply."