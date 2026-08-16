---
title: Walkthrough
layout: default
nav_order: 3
---

# Walkthrough
{: .no_toc }

From a laptop with AWS CLI profile `sandbox` and Terraform. Region
`ap-southeast-2`.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

## Prerequisites

- AWS CLI + Session Manager plugin
- Terraform
- Docker is **not** required on the laptop; tasks pull public GHCR images

## Clone

```bash
git clone git@github.com:jajera/seiscomp-ecs-lab.git
cd seiscomp-ecs-lab
export AWS_PROFILE=sandbox AWS_DEFAULT_REGION=ap-southeast-2 AWS_PAGER=""
```

## Create

```bash
./scripts/ecs-up.sh
```

That script:

1. Reads your public IP for GUI RDP `/32`
2. `terraform apply` with `deploy_services=false` (VPC, NAT, endpoints, RDS, EFS,
   IAM, Cloud Map)
3. `terraform apply` with `deploy_services=true` (Fargate tasks, internal FDSNWS
   ALB, GUI in a public subnet with an Elastic IP)

Fargate and the GUI instance pull `ghcr.io/platformfuzz/seiscomp-*`. There is no
laptop gsm build.

## Prove

```bash
./scripts/ecs-prove.sh
```

That waits until Fargate `runningCount` matches `desiredCount`. Inventory import
on `scmaster` can take a few minutes. Then [Prove]({{ site.baseurl }}/prove/)
and [Desktop]({{ site.baseurl }}/desktop/).

### Connect from Windows (no AWS CLI)

Remote Desktop to the GUI **Elastic IP**.

1. Open Remote Desktop Connection (`mstsc`).
2. Computer: Terraform output `gui_public_ip` (TCP 3389).
3. User: `sysop`.
4. Session type: **Xorg**.
5. Accept the self-signed certificate warning.

Password (from a machine that does have AWS CLI):

```bash
aws ssm get-parameter --name /seiscomp-ecs-lab/sysop-rdp-password \
  --with-decryption --query Parameter.Value --output text
```

If your public IP changed, re-apply with the new `/32` as `operator_cidr` so the
GUI security group allows 3389.

Internal FDSNWS is only reachable from inside the VPC (GUI or a task): the ALB
DNS on port 8080.

GUI shell (optional, AWS CLI):

```bash
IID=$(terraform -chdir=aws/ecs output -raw gui_instance_id)
aws ssm start-session --target "$IID"
```
