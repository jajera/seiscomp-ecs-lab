---
title: Prove
layout: default
nav_order: 4
---

# Prove
{: .no_toc }

Checks from the laptop after `ecs-up.sh`. SeedLink, scmaster, and FDSNWS are
private. RDP is the GUI Elastic IP.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

## Laptop

```bash
export AWS_PROFILE=sandbox AWS_DEFAULT_REGION=ap-southeast-2
./scripts/ecs-prove.sh
```

Expect every listed service `runningCount` equal to `desiredCount`: `scmaster`,
`seedlink`, `slarchive`, `fdsnws`, `scautopick`, `scautoloc`, `scamp`, `scmag`,
`scevent`, `scqc`, `scevtlog`. The script also prints the RDS endpoint, GUI
Elastic IP, and GUI SSM ping.

Inventory import on `scmaster` can take several minutes. Do not treat
`desiredCount` 1 with `runningCount` 0 as a finished lab.

Processors use `--console 1` so they stay in the foreground. Do not require
`seiscomp check` (that is the systemd / `seiscomp start` path).

## From the GUI (inside the VPC)

SSM or RDP onto the GUI instance, then:

```bash
python3 -c 'import socket; socket.create_connection(("seedlink.scnet",18000),5).close(); print("seedlink ok")'
python3 -c 'import socket; socket.create_connection(("scmaster.scnet",18180),5).close(); print("scmaster ok")'
```

Internal FDSNWS (ALB DNS from `terraform -chdir=aws/ecs output fdsnws_alb_dns`):

```bash
curl -sS "http://${ALB}:8080/fdsnws/station/1/version"
curl -sS "http://${ALB}:8080/fdsnws/station/1/query?net=GE&level=station&format=text"
```

Expect four GE stations (`MORC`, `RGN`, `STU`, `WLF`). Dataselect needs SDS data
on EFS; wait a few minutes after first start.

## What this does not prove

Locations with four GE stations may be rare. Empty `scolv` is normal. Desktop
checks are on [Desktop]({{ site.baseurl }}/desktop/).
