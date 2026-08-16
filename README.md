# seiscomp-ecs-lab

Unofficial LEARN SeisComP on ECS Fargate, private RDS, EFS for SDS, and a public
EC2 GUI (Elastic IP, Windows RDP). Images are public gsm on GHCR, not a source
compile.

This is **not** gempa-supported.

Docs: [jajera.github.io/seiscomp-ecs-lab](https://jajera.github.io/seiscomp-ecs-lab/)

| | |
|---|---|
| AWS CLI profile | `sandbox` |
| Region | `ap-southeast-2` |
| Tags | `Project=seiscomp-ecs-lab`, `Stack=fargate` |
| SeisComP | 7.3.1 public gsm + `world-minimal` |
| Access | Windows `mstsc` to the GUI Elastic IP `:3389` from your `/32`; SSM shell optional |

## Layout

```text
aws/ecs/          Terraform: VPC, NAT, endpoints, RDS, EFS, ECS, GUI
scripts/ecs-*.sh  apply, prove, destroy
docs/             Jekyll walkthrough (GitHub Pages)
```

## Start here (sandbox)

Needs Terraform. Tasks pull public GHCR images (no laptop Docker build).

```bash
git clone git@github.com:jajera/seiscomp-ecs-lab.git
cd seiscomp-ecs-lab
export AWS_PROFILE=sandbox AWS_DEFAULT_REGION=ap-southeast-2
./scripts/ecs-up.sh
./scripts/ecs-prove.sh
./scripts/ecs-destroy.sh
```

RDP as `sysop`, session **Xorg**, from Windows Remote Desktop to the Elastic IP
(no AWS CLI on Windows). Password: SSM `/seiscomp-ecs-lab/sysop-rdp-password`.

Local docs preview: `./scripts/docs-serve.sh`.
