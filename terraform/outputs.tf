output "vpc_id" {
  description = "ID of the default VPC"
  value       = data.aws_vpc.default.id
}

output "subnet_id" {
  description = "ID of the subnet where instances are deployed"
  value       = local.subnet_id
}

output "ssh_key_path" {
  description = "Path to the SSH private key"
  value       = local_file.private_key.filename
}

output "ssh_commands" {
  description = "SSH commands to connect to instances"
  value = {
    web_server     = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.web_server.public_ip}"
    db_server      = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.db_server.public_ip}"
    monitor_server = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.monitor_server.public_ip}"
    loadgenerator  = "ssh -i ${local_file.private_key.filename} ec2-user@${aws_instance.loadgenerator.public_ip}"
  }
}

output "access_urls" {
  description = "Web access URLs"
  value = {
    grafana              = "http://${aws_instance.monitor_server.public_ip}:3000 (Default: admin/admin)"
    prometheus           = "http://${aws_instance.monitor_server.public_ip}:9090"
    prometheus_targets   = "http://${aws_instance.monitor_server.public_ip}:9090/targets"
    flask_health         = "http://${aws_instance.web_server.public_ip}:5000/health"
    flask_order_get      = "http://${aws_instance.web_server.public_ip}:5000/api/order/1"
    flask_metrics        = "http://${aws_instance.web_server.public_ip}:8000/metrics"
    flask_node_exporter  = "http://${aws_instance.web_server.public_ip}:9100/metrics"
    db_mysql_exporter    = "http://${aws_instance.db_server.public_ip}:9104/metrics"
    db_node_exporter     = "http://${aws_instance.db_server.public_ip}:9100/metrics"
    locust               = "http://${aws_instance.loadgenerator.public_ip}:8089"
  }
}
