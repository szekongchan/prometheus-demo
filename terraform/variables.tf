variable "aws_region" {
  description = "AWS region for resource deployment"
  type        = string
  default     = "ap-southeast-1"
}

variable "project_name" {
  description = "Environment name"
  type        = string
  default     = "sk-prometheus-demo"
}

variable "instance_type" {
  description = "EC2 instance type for all servers"
  type        = string
  default     = "t2.micro"
}

variable "db_app_user" {
  description = "Database username for the web app"
  type        = string
  default     = "app_user"
}

variable "db_app_password" {
  description = "Database password for the web app"
  type        = string
  sensitive   = true
}

variable "db_name" {
  description = "Database name used by the web app"
  type        = string
  default     = "orders_db"
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 3306
}

variable "db_root_password" {
  description = "MySQL root password"
  type        = string
  sensitive   = true
}

variable "db_exporter_password" {
  description = "MySQL exporter user password"
  type        = string
  sensitive   = true
}
