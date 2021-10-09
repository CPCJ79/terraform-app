variable "allowed_inbound_cidr_blocks" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Security Group."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "allowed_ssh_cidrs" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Security Group."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "app_cidr" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Security Group."
  type        = list(string)
  default     = ["10.0.0.0/8"]
}

variable "app_name" {
  description = "Name of the application being deployed."
  type        = string
}

variable "app_port" {
  description = "Port number for the application to communicate on."
  type        = number
  default     = null
}

variable "app_proto" {
  description = "Application layer protocol 'HTTP', 'HTTPS', 'TCP', 'UDP', or  'ICMP'."
  type        = string
  default     = null
}

variable "db_instance" {
  description = "Database instance type, only 'postgres' is currently supported."
  type        = string
  default     = null
}

variable "db_name" {
  description = "Name for the RDS database."
  type        = string
  default     = null
}

variable "dep_subnet" {
  description = "Type of subnet to deploy the application into, 'private' or 'protected'."
  type        = string
  default     = "private"
  validation {
    condition     = can(regex("private|protected", var.dep_subnet))
    error_message = "ERROR: Subnet type must be either 'private' or 'protected'."
  }
}

variable "enable_efs" {
  description = "Set 'true' to enable persistent storage."
  type        = bool
  default     = false
}

variable "health_enabled" {
  description = ""
  type        = bool
  default     = true
}

variable "health_path" {
  description = "Path to set a custom health check path for the load balancer."
  type        = string
  default     = "/"
}

variable "health_response" {
  description = "HTTP status code required for health check on the load balancer."
  type        = string
  default     = "200"
}

variable "instance_type" {
  description = "Instance type to be provisiooned, example 't3.medium'."
  type        = string
  default     = "t3.medium"
}

variable "lb_port" {
  description = "Port number for the load balancer to communicate on."
  type        = string
  default     = null
}

variable "lb_proto" {
  description = "Load balancer layer protocol 'HTTP', 'HTTPS', 'TCP', 'UDP', or  'ICMP'."
  type        = string
  default     = null
}

variable "load_balancer_type" {
  description = "Type of load balancer to provision, 'application', 'network' or 'none'."
  type        = string
}

variable "max_instance" {
  description = "Maximum instance count for the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "min_instance" {
  description = "Minimum instance count for the Auto Scaling Group."
  type        = number
  default     = 1
}

variable "needs_rds_instance" {
  description = "Set 'true' to enable RDS database."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A dict of optional tags to be applied to resources created by this module."
  type        = map(string)
  default     = {}
}

variable "user_data" {
  description = "Path to user_data script to run on instance creation."
}

variable "vpc_name" {
  description = "Name of VPC to deploy resource into."
  type        = string
  default     = "main"
}
