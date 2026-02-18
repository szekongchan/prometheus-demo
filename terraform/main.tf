terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.31.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = ">= 4.0.0"
    }
    local = {
      source  = "hashicorp/local"
      version = ">= 2.5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

locals {
  subnet_id = sort(data.aws_subnets.default.ids)[0]
  web_user_data = templatefile("${path.module}/user-data/web_server.sh.tftpl", {
    app_py                = file("${path.module}/../src/app.py")
    requirements          = file("${path.module}/../src/requirements.txt")
    service_file          = file("${path.module}/../services/order-api.service")
    node_exporter_service = file("${path.module}/../services/node_exporter.service")
    db_host               = aws_instance.db_server.private_ip
    db_port               = var.db_port
    db_user               = var.db_app_user
    db_password           = var.db_app_password
    db_name               = var.db_name
  })
  db_user_data = templatefile("${path.module}/user-data/db_server.sh.tftpl", {
    schema_sql              = file("${path.module}/../db/schema.sql")
    seed_sql                = file("${path.module}/../db/seed.sql")
    mysqld_exporter_service = file("${path.module}/../services/mysqld_exporter.service")
    node_exporter_service   = file("${path.module}/../services/node_exporter.service")
    db_root_password        = var.db_root_password
    db_user                 = var.db_app_user
    db_password             = var.db_app_password
    db_name                 = var.db_name
    exporter_password       = var.db_exporter_password
  })
  monitor_user_data = templatefile("${path.module}/user-data/monitor_server.sh.tftpl", {
    prometheus_config     = templatefile("${path.module}/../monitoring/prometheus.yml", {
      web_private_ip = aws_instance.web_server.private_ip
      db_private_ip  = aws_instance.db_server.private_ip
    })
    prometheus_service  = file("${path.module}/../services/prometheus.service")
    grafana_datasource  = file("${path.module}/../monitoring/grafana-datasource.yaml")
    dashboard_json      = file("${path.module}/../monitoring/dashboards/prometheus-demo-dashboard.json")
  })
  loadgenerator_user_data = templatefile("${path.module}/user-data/loadgenerator.sh.tftpl", {
    locustfile     = file("${path.module}/../loadtest/locustfile.py")
    locust_service = file("${path.module}/../services/locust.service")
    target_host    = aws_instance.web_server.private_ip
  })
}

data "aws_ssm_parameter" "amazon_linux_2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

# Create SSH key pair
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ssh" {
  key_name   = "${var.project_name}-keypair"
  public_key = tls_private_key.ssh.public_key_openssh
}

# Save private key locally
resource "local_file" "private_key" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = pathexpand("~/.ssh/${var.project_name}-keypair.pem")
  file_permission = "0400"
}

resource "aws_security_group" "common" {
  name        = "${var.project_name}-sg"
  description = "Common security group for all demo servers"
  vpc_id      = data.aws_vpc.default.id

  tags = {
    Name = "${var.project_name}-sg"
  }
}

# SSH access from anywhere
resource "aws_security_group_rule" "common_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Flask API port (5000)
resource "aws_security_group_rule" "common_flask" {
  type              = "ingress"
  from_port         = 5000
  to_port           = 5000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Grafana port (3000)
resource "aws_security_group_rule" "common_grafana" {
  type              = "ingress"
  from_port         = 3000
  to_port           = 3000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# MySQL port (3306)
resource "aws_security_group_rule" "common_mysql" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Flask metrics port (8000)
resource "aws_security_group_rule" "common_flask_metrics" {
  type              = "ingress"
  from_port         = 8000
  to_port           = 8000
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Locust port (8089)
resource "aws_security_group_rule" "common_locust" {
  type              = "ingress"
  from_port         = 8089
  to_port           = 8089
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Prometheus port (9090)
resource "aws_security_group_rule" "common_prometheus" {
  type              = "ingress"
  from_port         = 9090
  to_port           = 9090
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Node exporter port (9100)
resource "aws_security_group_rule" "common_node_exporter" {
  type              = "ingress"
  from_port         = 9100
  to_port           = 9100
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# MySQL exporter port (9104)
resource "aws_security_group_rule" "common_mysql_exporter" {
  type              = "ingress"
  from_port         = 9104
  to_port           = 9104
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# Egress to anywhere
resource "aws_security_group_rule" "common_egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.common.id
}

# IAM role for EC2 to write to AMP
resource "aws_iam_role" "ec2_amp_role" {
  name = "${var.project_name}-ec2-amp-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.project_name}-ec2-amp-role"
  }
}

# Attach SSM policy for EC2 instance management (optional but useful)
resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.ec2_amp_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# IAM instance profile
resource "aws_iam_instance_profile" "ec2_amp_profile" {
  name = "${var.project_name}-ec2-amp-profile"
  role = aws_iam_role.ec2_amp_role.name

  tags = {
    Name = "${var.project_name}-ec2-amp-profile"
  }
}

# Web Server Instance
resource "aws_instance" "web_server" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.common.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_amp_profile.name
  user_data                   = local.web_user_data
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-webserver"
  }
}

# DB Server Instance
resource "aws_instance" "db_server" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.common.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_amp_profile.name
  user_data                   = local.db_user_data
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-dbserver"
  }
}

# Monitor Server Instance
resource "aws_instance" "monitor_server" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.common.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_amp_profile.name
  user_data                   = local.monitor_user_data
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-monitorserver"
  }
}

# Load Gen Server Instance
resource "aws_instance" "loadgenerator" {
  ami                         = data.aws_ssm_parameter.amazon_linux_2023.value
  instance_type               = var.instance_type
  subnet_id                   = local.subnet_id
  vpc_security_group_ids      = [aws_security_group.common.id]
  associate_public_ip_address = true
  key_name                    = aws_key_pair.ssh.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_amp_profile.name
  user_data                   = local.loadgenerator_user_data
  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-loadgenerator"
  }
}
