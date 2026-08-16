---
title: Overview
layout: default
nav_order: 1
---

<div class="conduit-hero">
  <p class="conduit-kicker">jajera · seiscomp-ecs-lab</p>
  <h1>SeisComP ECS lab</h1>
  <p class="conduit-lede">
    LEARN SeisComP as one Fargate task per process. Catalog on RDS, SDS on EFS,
    GUI on EC2. Images from public gsm on GHCR. Unofficial. Not gempa-supported.
  </p>
  <div class="conduit-actions">
    <a class="conduit-btn conduit-btn--primary" href="{{ site.baseurl }}/walkthrough/">Deploy the lab</a>
    <a class="conduit-btn conduit-btn--ghost" href="{{ site.baseurl }}/architecture/">See architecture</a>
  </div>
</div>

## What you build

A private VPC in `ap-southeast-2`. Fargate runs scmaster, seedlink, slarchive,
the processors, and fdsnws. MariaDB is RDS. Waveforms live on EFS. A public
Ubuntu EC2 runs the XFCE + xrdp GUI. You reach the desktop with Windows Remote
Desktop to an Elastic IP. Shell on that box is optional via SSM.

The Compose-on-one-EC2 lab is
[seiscomp-containers-lab](https://github.com/jajera/seiscomp-containers-lab).
This repo is the Fargate composition and its walkthrough.

## Read in this order

<div class="nav-grid">
  <a class="nav-card" href="{{ site.baseurl }}/architecture/">
    <strong>1. Architecture</strong>
    <span>VPC, Fargate, RDS, EFS, GUI</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/walkthrough/">
    <strong>2. Deploy the lab</strong>
    <span>clone, ecs-up</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/prove/">
    <strong>3. Prove</strong>
    <span>Service counts, RDP, FDSNWS</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/desktop/">
    <strong>4. Desktop</strong>
    <span>RDP, launchers, scrttv</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/troubleshooting/">
    <strong>Troubleshooting</strong>
    <span>Health, client names, placement</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/reference/">
    <strong>Reference</strong>
    <span>File map and SSM</span>
  </a>
  <a class="nav-card" href="{{ site.baseurl }}/conclusion/">
    <strong>Conclusion</strong>
    <span>What improved, what still wobbles</span>
  </a>
</div>

## Scope

| In | Out |
|---|---|
| Ubuntu 24.04, SeisComP 7.3.1 public gsm, `world-minimal` | gempa private/commercial gsm |
| One GHCR image and one Fargate task per process | Fat all-in-one container |
| Catalog on RDS, SDS on EFS | Catalog on EFS |
| Four GEOFON BH stations | Public SeedLink or scmaster |
| XFCE + xrdp on EC2 | Amazon DCV, GUI on Fargate |
| RDP from `operator_cidr`, SSM for shell | Inbound SSH |

{: .cost }
> NAT Gateway, RDS, EFS, Fargate, the GUI instance, and VPC endpoints all bill
> while they exist. Destroy when you are done. See
> [Conclusion]({{ site.baseurl }}/conclusion/#destroy).
