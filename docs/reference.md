---
title: Reference
layout: default
nav_order: 7
---

# Reference
{: .no_toc }

File map for the Fargate lab. Images are GHCR, not a laptop gsm build.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

## Paths

| Path | Role |
|---|---|
| `aws/ecs/` | VPC, NAT, endpoints, RDS, EFS, ECS, internal FDSNWS ALB, GUI EC2 |
| `scripts/ecs-up.sh` | two-phase Terraform apply |
| `scripts/ecs-prove.sh` | service counts + GUI SSM ping |
| `scripts/ecs-destroy.sh` | terraform destroy |
| `scripts/docs-serve.sh` | local Jekyll preview |
| `compose.yaml`, `docker/` | leftover laptop compose; not the run path |
| `config/key/` | four GEOFON BH station keys (baked into images too) |

## Images

`ghcr.io/platformfuzz/seiscomp-*` with tag `latest` unless you set `image_tag`.
Ubuntu 24.04, SeisComP 7.3.1 public gsm, `world-minimal`.

## SSM

| Parameter | Use |
|---|---|
| `/seiscomp-ecs-lab/db-password` | RDS `sysop` |
| `/seiscomp-ecs-lab/sysop-rdp-password` | GUI RDP |

## Cloud Map

Namespace `scnet`: `seedlink.scnet:18000`, `scmaster.scnet:18180`.
