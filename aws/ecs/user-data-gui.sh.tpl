#!/bin/bash
set -euxo pipefail
exec > >(tee /var/log/gui-user-data.log) 2>&1
export DEBIAN_FRONTEND=noninteractive
export AWS_DEFAULT_REGION="${region}"

apt-get update -y
apt-get install -y docker.io ca-certificates curl unzip
systemctl enable --now docker

if ! command -v aws >/dev/null; then
  curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscliv2.zip
  unzip -q /tmp/awscliv2.zip -d /tmp
  /tmp/aws/install
fi

for i in $(seq 1 30); do
  if docker pull "${image}"; then
    break
  fi
  sleep 10
done

PASS=$(aws ssm get-parameter --name "${rdp_param}" --with-decryption --query Parameter.Value --output text)
DBPASS=$(aws ssm get-parameter --name "${db_param}" --with-decryption --query Parameter.Value --output text)

docker pull "${image}"
docker rm -f gui || true
docker run -d --name gui --restart unless-stopped \
  --network host --shm-size 2g \
  -e SYSOP_PASSWORD="$PASS" \
  -e WAIT_FOR_DB=0 \
  -e DB_HOST="${db_host}" \
  -e DB_USER=sysop \
  -e DB_PASSWORD="$DBPASS" \
  -e DB_NAME=seiscomp \
  -e SEEDLINK_HOST="${seedlink_host}" \
  -e SCMASTER_HOST="${scmaster_host}" \
  "${image}"
