variable "project" {
  type    = string
  default = "seiscomp-ecs-lab"
}

variable "region" {
  type    = string
  default = "ap-southeast-2"
}

variable "profile" {
  type    = string
  default = "sandbox"
}

variable "operator_cidr" {
  type        = string
  description = "Public /32 allowed to TCP 3389 on the GUI Elastic IP."
}

variable "vpc_cidr" {
  type    = string
  default = "10.82.0.0/16"
}

variable "image_tag" {
  type        = string
  default     = "latest"
  description = "GHCR tag for platformfuzz/seiscomp-* images."
}

variable "deploy_services" {
  type        = bool
  default     = false
  description = "Create ECS services and GUI after the network and RDS exist."
}

variable "gui_instance_type" {
  type    = string
  default = "t3.large"
}

variable "fdsnws_count" {
  type    = number
  default = 1
}

variable "nat_az_index" {
  type        = number
  default     = 0
  description = "Public subnet index that holds the single lab NAT Gateway."
}

variable "seedlink_upstream_host" {
  type        = string
  default     = "geofon.gfz.de"
  description = "SeedLink chain plugin upstream host (SEEDLINK_UPSTREAM_HOST)."
}

variable "seedlink_upstream_port" {
  type        = number
  default     = 18000
  description = "SeedLink chain plugin upstream port (SEEDLINK_UPSTREAM_PORT)."
}

variable "seedlink_network" {
  type        = string
  default     = "GE"
  description = "Network code for station keys (SEEDLINK_NETWORK)."
}

variable "seedlink_stations" {
  type        = string
  default     = "WLF,STU,MORC,RGN"
  description = "Comma-separated station codes, or * for every station the upstream advertises."
}

variable "seedlink_selectors" {
  type        = string
  default     = "BH?.D"
  description = "SeedLink chain selectors. * means all streams."
}

variable "inventory_fdsn_base" {
  type        = string
  default     = "https://geofon.gfz.de/fdsnws/station/1/query"
  description = "FDSN Station query base used to import inventory at start."
}

variable "inventory_fdsn_level" {
  type        = string
  default     = "response"
  description = "FDSN station query level (channel or response)."
}

variable "inventory_min_stations" {
  type        = number
  default     = 4
  description = "scmaster waits until MariaDB has at least this many Station rows."
}
