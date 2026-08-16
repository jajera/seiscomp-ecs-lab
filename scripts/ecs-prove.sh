#!/usr/bin/env bash
# Show Fargate service counts. Optional: SSM on the GUI box.
# Usage: AWS_PROFILE=sandbox ./scripts/ecs-prove.sh
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-sandbox}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-southeast-2}"
export AWS_PAGER=""

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF="$ROOT/aws/ecs"
CLUSTER=$(terraform -chdir="$TF" output -raw cluster)
SVCS="scmaster seedlink slarchive fdsnws scautopick scautoloc scamp scmag scevent scqc scevtlog"

echo "=== ECS services (wait until running=desired) ==="
ok=0
for _ in $(seq 1 24); do
  aws ecs describe-services --cluster "$CLUSTER" --services $SVCS \
    --query 'services[].{name:serviceName,running:runningCount,desired:desiredCount}' \
    --output table
  pending=$(aws ecs describe-services --cluster "$CLUSTER" --services $SVCS \
    --query 'length(services[?runningCount!=desiredCount])' --output text)
  if [ "${pending:-1}" = "0" ]; then
    ok=1
    break
  fi
  echo "waiting for tasks..."
  sleep 15
done
if [ "$ok" != "1" ]; then
  echo "services still not at desired count" >&2
  exit 1
fi

echo "=== RDS ==="
terraform -chdir="$TF" output rds_endpoint

echo "=== GUI RDP EIP ==="
terraform -chdir="$TF" output gui_public_ip

IID=$(terraform -chdir="$TF" output -raw gui_instance_id)
echo "=== GUI SSM $IID ==="
aws ssm describe-instance-information \
  --filters "Key=InstanceIds,Values=$IID" \
  --query 'InstanceInformationList[0].PingStatus' --output text
