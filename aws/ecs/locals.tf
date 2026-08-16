data "aws_availability_zones" "available" {
  state = "available"
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  public_cidrs = ["10.82.1.0/24", "10.82.2.0/24"]
  app_cidrs    = ["10.82.11.0/24", "10.82.12.0/24"]
  db_cidrs     = ["10.82.21.0/24", "10.82.22.0/24"]

  processors = toset([
    "scautopick",
    "scautoloc",
    "scamp",
    "scmag",
    "scevent",
    "scqc",
    "scevtlog",
  ])

  namespace       = "scnet"
  seedlink_dns    = "seedlink.${local.namespace}"
  scmaster_dns    = "scmaster.${local.namespace}"
  ghcr            = "ghcr.io/platformfuzz"
  image_tag       = var.image_tag
  image_gui       = "${local.ghcr}/seiscomp-gui:${local.image_tag}"
  image_scmaster  = "${local.ghcr}/seiscomp-scmaster:${local.image_tag}"
  image_seedlink  = "${local.ghcr}/seiscomp-seedlink:${local.image_tag}"
  image_slarchive = "${local.ghcr}/seiscomp-slarchive:${local.image_tag}"
  image_fdsnws    = "${local.ghcr}/seiscomp-fdsnws:${local.image_tag}"
  image_processor = {
    for name in local.processors : name => "${local.ghcr}/seiscomp-${name}:${local.image_tag}"
  }
  ssm_db  = "/${var.project}/db-password"
  ssm_rdp = "/${var.project}/sysop-rdp-password"
  name    = var.project
}
