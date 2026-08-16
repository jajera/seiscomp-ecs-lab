---
title: Desktop
layout: default
nav_order: 5
---

# Desktop
{: .no_toc }

XFCE and xrdp run in the `seiscomp-gui` container on the GUI EC2, with host
networking and 2g shm.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

## Connect

| Item | Value |
|---|---|
| User | `sysop` |
| Session | **Xorg** |
| Password | SSM `/seiscomp-ecs-lab/sysop-rdp-password` |
| Port | TCP 3389 from your `/32` to the Elastic IP |

```bash
export AWS_PROFILE=sandbox AWS_DEFAULT_REGION=ap-southeast-2
aws ssm get-parameter --name /seiscomp-ecs-lab/sysop-rdp-password \
  --with-decryption --query Parameter.Value --output text
terraform -chdir=aws/ecs output -raw gui_public_ip
```

`ecs-up.sh` prints the Elastic IP. In Remote Desktop, pick session **Xorg** and
accept the certificate warning. Windows does not need AWS CLI.

{: .warning }
> If your public IP changed, 3389 will time out until you re-apply with the new
> `/32` as `operator_cidr`.

## On the desktop

1. Terminal: `/home/sysop/bin/sc-toast-event "test toast"` — notification titled
   SeisComP. Needs xfce4-notifyd in this RDP session; SSM cannot show it.
2. **scrttv** — live BH for the four GE stations. Add streams if the view is empty.
3. **scmm** — `scmaster` plus processor clients.
4. Optional: **scmv**, **scheli**, **scqcv**.

Launchers call `/home/sysop/bin/sc-launch`, which writes a unique
`connection.clientName` so two GUI tools of the same module do not collide.

## What stays quiet

Real earthquake toasts need picks and an event. Four GEOFON stations are often
quiet. The scripted toast is the desktop proof. **scolv** stays empty until there
is an event.
