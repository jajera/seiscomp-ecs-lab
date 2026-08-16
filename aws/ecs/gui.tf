data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd*/ubuntu-noble-24.04-amd64-server-*"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

resource "aws_instance" "gui" {
  count                       = var.deploy_services ? 1 : 0
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.gui_instance_type
  subnet_id                   = aws_subnet.public[0].id
  vpc_security_group_ids      = [aws_security_group.app.id, aws_security_group.gui_rdp[0].id]
  iam_instance_profile        = aws_iam_instance_profile.gui.name
  associate_public_ip_address = true

  user_data = templatefile("${path.module}/user-data-gui.sh.tpl", {
    region        = var.region
    image         = local.image_gui
    rdp_param     = local.ssm_rdp
    db_param      = local.ssm_db
    db_host       = aws_db_instance.this.address
    seedlink_host = local.seedlink_dns
    scmaster_host = local.scmaster_dns
  })

  root_block_device {
    volume_size = 40
    volume_type = "gp3"
  }

  user_data_replace_on_change = true

  metadata_options {
    http_tokens = "required"
  }

  tags = { Name = "${local.name}-gui" }

  depends_on = [
    aws_vpc_endpoint.interface,
    aws_vpc_endpoint.s3,
    aws_nat_gateway.this,
    aws_internet_gateway.this,
  ]
}

resource "aws_eip" "gui" {
  count    = var.deploy_services ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.gui[0].id
  tags     = { Name = "${local.name}-gui" }
}
