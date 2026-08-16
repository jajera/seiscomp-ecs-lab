---
title: Troubleshooting
layout: default
nav_order: 6
---

# Troubleshooting
{: .no_toc }

Failures from bringing this Fargate lab up.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

## scmaster unhealthy, everything else looks dead

scmaster is the messaging bus. If ECS kills it during start, processors and the
GUI lose `18180`.

`seiscomp update-config` talks to localhost:18180 and can start a kernel
scmaster before the run script `exec`s the real process. Inventory and
`update-config trunk` can run longer than the Fargate health `startPeriod`
(capped at 300s). The container then fails health checks (often exit 137).

Logs: `/ecs/seiscomp-ecs-lab` stream `ecs/scmaster/<task-id>`. Wait until 18180
accepts TCP before treating other services as broken.

## Client name not unique

Default SeisComP client name is the module name. Two `scolv` or two
`scautopick` tasks collide. Processors set
`connection.clientName = $MODULE-$HOSTNAME`. GUI `sc-launch` writes a per-process
name in `~/.seiscomp`. Do not start a second copy of the same GUI tool without
that.

## Processors empty, no bindings

Do not run `seiscomp update-config` in processor images. `trunk.py` always
connects to localhost:18180. Bindings are written on the scmaster task.

## Fargate tasks pending, vCPU

Eleven services at 0.25–0.5 vCPU add up. A simultaneous bounce can fail
placement. `deployment_maximum_percent = 100` is required for singletons (no two
scmasters). Restart one service at a time.

## var/run missing

`seiscomp` opens `/home/sysop/seiscomp/var/run/seiscomp.pid`. Entrypoints mkdir
that path. A new image that forgets it dies immediately.

## 3389 times out

Your public IP changed. Re-apply with the current `/32` as `operator_cidr`.

## GUI still shows an old catalog

The GUI container does not reload MariaDB inventory by itself. Restart the GUI
Docker container after scmaster has finished inventory, then open a new scrttv.
