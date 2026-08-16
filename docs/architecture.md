---
title: Architecture
layout: default
nav_order: 2
---

# Architecture
{: .no_toc }

Private-by-default AWS lab: RDS, ECS Fargate, EFS for SDS only, and one public
GUI EC2. NAT is for GEOFON. AWS APIs use VPC endpoints.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

`compose.yaml` in this folder is leftover laptop compose. The running system is
Terraform in `aws/ecs/`. Tasks pull `ghcr.io/platformfuzz/seiscomp-*`.

## Why this split

- **SDS** is the only shared POSIX tree (`slarchive` writes, `fdsnws` reads
  `sdsarchive://`). That is EFS.
- **Catalog** is InnoDB on private RDS MariaDB (`utf8mb4_bin`). Not EFS.
- **GUI** needs `shm_size: 2gb`. Fargate cannot set `/dev/shm`. GUI stays on EC2.

{% include diagram-dataflow.html %}

{% include diagram-network.html %}

## Network

VPC `10.82.0.0/16`, two AZs, tags `Project=seiscomp-ecs-lab` and `Stack=fargate`.

| Tier | CIDRs | What lives here |
|---|---|---|
| Public | `10.82.1.0/24`, `10.82.2.0/24` | IGW, NAT Gateway, GUI EC2 + Elastic IP |
| Private app | `10.82.11.0/24`, `10.82.12.0/24` | Fargate (`assignPublicIp` off), EFS, interface VPC endpoints |
| Private db | `10.82.21.0/24`, `10.82.22.0/24` | RDS only, not publicly accessible, no NAT |

**Public inbound:** TCP **3389** from your `/32` to the GUI Elastic IP. No public
SeedLink, scmaster, fdsnws, or RDS. The sandbox account rejected a second public
load balancer after the internal FDSNWS ALB existed, so RDP is not on an NLB.

**NAT egress:** SeedLink to `geofon.gfz.de:18000`.

**VPC endpoints:** S3 gateway (ECR layers); interface ECR (`ecr.api`, `ecr.dkr`),
CloudWatch Logs, SSM (`ssm`, `ssmmessages`, `ec2messages`).

Cloud Map namespace `scnet`: `connection.server = scmaster.scnet/production`,
`recordstream = slink://seedlink.scnet:18000`. Entrypoints rewrite `global.cfg`
from `SEEDLINK_HOST` / `SCMASTER_HOST` (short Compose names do not resolve on
Fargate).

## Storage

| Data | Where | Who mounts |
|---|---|---|
| Catalog | Private RDS MariaDB 11.4, utf8mb4_bin | DSN via `DB_HOST` / SSM password |
| SDS | EFS access point uid/gid 1000 | `slarchive` RW, `fdsnws` RO |
| SeedLink ring | Fargate ephemeral | `seedlink` only |
| GUI shm | EC2 `--shm-size 2g` | `gui` only |

`slarchive` desired count is **1**. `fdsnws` can be N behind the internal ALB.

## ECS Fargate services

One task definition per process:

- `scmaster` — 18180, Cloud Map `scmaster`
- `seedlink` — 18000, Cloud Map `seedlink`
- `slarchive` — EFS RW, count 1
- `scautopick`, `scautoloc`, `scamp`, `scmag`, `scevent`, `scqc`, `scevtlog`
- `fdsnws` — EFS RO, 8080, internal ALB

MariaDB is RDS, not a task. Secrets: `/seiscomp-ecs-lab/db-password` and
`/seiscomp-ecs-lab/sysop-rdp-password`.

Processors do not run `seiscomp update-config`. `trunk.py` talks to
localhost:18180. Bindings are written on the scmaster task.
`connection.clientName` is `$MODULE-$HOSTNAME` so two tasks of the same module
do not collide.

## GUI

Public Ubuntu EC2 (Elastic IP) runs `seiscomp-gui` with host networking and 2g
shm. Windows RDP to `:3389` from `operator_cidr`. Shell via SSM. No EFS on the
GUI; `scrttv` uses SeedLink.
