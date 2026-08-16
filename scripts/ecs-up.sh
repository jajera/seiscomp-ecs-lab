#!/usr/bin/env bash
# Private VPC + RDS + EFS + Fargate + GUI. Tasks pull public GHCR images.
# Usage: AWS_PROFILE=sandbox AWS_DEFAULT_REGION=ap-southeast-2 ./scripts/ecs-up.sh
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-sandbox}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-southeast-2}"
export AWS_PAGER=""

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF="$ROOT/aws/ecs"
TAG_PROJECT="${TAG_PROJECT:-seiscomp-ecs-lab}"

command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 1; }
PASS_PARAM="/${TAG_PROJECT}/sysop-rdp-password"

MYIP=$(curl -sS https://checkip.amazonaws.com | tr -d '[:space:]')
echo "operator IP ${MYIP}"

terraform -chdir="$TF" init -input=false

echo "=== apply network, RDS, EFS, ECR (no tasks yet) ==="
terraform -chdir="$TF" apply -input=false -auto-approve \
  -var="operator_cidr=${MYIP}/32" \
  -var="deploy_services=false"

echo "=== apply Fargate services, GUI, NLB (GHCR images) ==="
terraform -chdir="$TF" apply -input=false -auto-approve \
  -var="operator_cidr=${MYIP}/32" \
  -var="deploy_services=true"

echo "GUI instance $(terraform -chdir="$TF" output -raw gui_instance_id)"
echo "Windows RDP (mstsc, no AWS CLI): $(terraform -chdir="$TF" output -raw gui_public_ip) user sysop session Xorg"
echo "Password: aws ssm get-parameter --name ${PASS_PARAM} --with-decryption --query Parameter.Value --output text"
echo "Internal FDSNWS $(terraform -chdir="$TF" output -raw fdsnws_alb_dns):8080"
echo "RDS $(terraform -chdir="$TF" output -raw rds_endpoint)"
