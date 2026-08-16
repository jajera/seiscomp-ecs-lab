#!/usr/bin/env bash
# Build seiscomp-base and seiscomp-gui and push to the lab ECR repos.
# Usage: AWS_PROFILE=sandbox AWS_DEFAULT_REGION=ap-southeast-2 ./scripts/ecs-push.sh
set -euo pipefail

export AWS_PROFILE="${AWS_PROFILE:-sandbox}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-ap-southeast-2}"
export AWS_PAGER=""
export COMPOSE_BAKE=false

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TF="$ROOT/aws/ecs"
TAG="${IMAGE_TAG:-7.3.1}"

command -v docker >/dev/null || { echo "docker is required to build and push images" >&2; exit 1; }
command -v terraform >/dev/null || { echo "terraform is required" >&2; exit 1; }

BASE=$(terraform -chdir="$TF" output -raw ecr_base)
GUI=$(terraform -chdir="$TF" output -raw ecr_gui)

aws ecr get-login-password | docker login --username AWS --password-stdin "${BASE%%/*}"

docker build -f "$ROOT/docker/Dockerfile" -t "seiscomp-base:${TAG}" "$ROOT"
docker tag "seiscomp-base:${TAG}" "${BASE}:${TAG}"
docker push "${BASE}:${TAG}"

docker build -f "$ROOT/docker/Dockerfile.gui" -t "seiscomp-gui:${TAG}" "$ROOT"
docker tag "seiscomp-gui:${TAG}" "${GUI}:${TAG}"
docker push "${GUI}:${TAG}"

echo "pushed ${BASE}:${TAG}"
echo "pushed ${GUI}:${TAG}"
