#!/usr/bin/env bash
# Tear down the Fargate stack (terraform destroy).
# Usage: AWS_PROFILE=sandbox ./scripts/ecs-destroy.sh
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-sandbox}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-southeast-2}"
export AWS_PAGER=""

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF="$ROOT/aws/ecs"
MYIP=$(curl -sS https://checkip.amazonaws.com | tr -d '[:space:]')

if [ ! -f "$TF/terraform.tfstate" ] && [ ! -f "$TF/.terraform/terraform.tfstate" ]; then
  echo "no terraform state in aws/ecs; nothing to destroy" >&2
  exit 1
fi

terraform -chdir="$TF" destroy -input=false -auto-approve \
  -var="operator_cidr=${MYIP}/32" \
  -var="deploy_services=true"
