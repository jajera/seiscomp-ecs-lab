output "vpc_id" {
  value = aws_vpc.this.id
}

output "ecr_base" {
  value = aws_ecr_repository.base.repository_url
}

output "ecr_gui" {
  value = aws_ecr_repository.gui.repository_url
}

output "rds_endpoint" {
  value = aws_db_instance.this.address
}

output "cluster" {
  value = aws_ecs_cluster.this.name
}

output "rdp_nlb_dns" {
  value       = null
  description = "No RDP NLB (sandbox LB quota). Windows uses the GUI Elastic IP on TCP 3389."
}

output "gui_public_ip" {
  value       = var.deploy_services ? aws_eip.gui[0].public_ip : null
  description = "Windows Remote Desktop (mstsc) target. User sysop, session Xorg."
}

output "fdsnws_alb_dns" {
  value = var.deploy_services ? aws_lb.fdsnws[0].dns_name : null
}

output "gui_instance_id" {
  value = var.deploy_services ? aws_instance.gui[0].id : null
}

output "image_tag" {
  value = var.image_tag
}

output "ssm_rdp" {
  value = local.ssm_rdp
}

output "ssm_db" {
  value = local.ssm_db
}
