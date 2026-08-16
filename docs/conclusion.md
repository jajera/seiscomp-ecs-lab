---
title: Conclusion
layout: default
nav_order: 8
---

# Conclusion
{: .no_toc }

What this lab shows, and what is still unfinished.
{: .fs-5 .fw-300 }

## On this page
{: .no_toc .text-delta }

- TOC
{:toc}

---

## What improved

SeisComP does not have to be one box with every module on one filesystem.
One process per container is a real step up from that monolith: SeedLink,
scmaster, archive, processors, and FDSNWS can start, fail, and update on their
own. Catalog on RDS and SDS on EFS match how the software already shares state.
The GUI stays on EC2 because Fargate cannot give it `/dev/shm`. That split is
worth keeping.

## What still wobbles

The split is less stable than a single host at times. SeisComP still assumes
localhost:18180, a unique client name per module, and a `var/run` pid file.
Inventory and `update-config` on scmaster can outlast the ECS health window, and
the bus disappearing makes every other task look broken. Eleven Fargate services
will miss placement if you bounce them together. The desktop can drift from the
catalog until you restart the GUI container.

This is a working LEARN lab, not a hardened network. More work is needed:
scmaster healthy as soon as 18180 accepts clients, less work on the critical
start path, and calmer deploys so the graph does not fall over as one unit.

## Destroy

```bash
./scripts/ecs-destroy.sh
```

This is `terraform destroy` of the `aws/ecs` state. It does not touch other labs.

{: .cost }
> NAT Gateway, RDS, EFS, Fargate, the GUI instance, and VPC endpoints all bill
> while they exist. Destroy when you are done.
