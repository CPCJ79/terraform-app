variable "app_name" {
  description = "Name of the application being deployed."
  type        = string
}

variable "health_path" {
  description = "Path to set a custom health check path for the load balancer."
  type        = string
  default     = null
}

variable "health_response" {
  description = "HTTP status code required for health check on the load balancer."
  type        = string
  default     = null
}

variable "lb_app_port" {
  description = "Port number for the application to communicate on."
  type        = number
  default     = "443"
}

variable "lb_app_proto" {
  description = "Application layer protocol 'HTTP', 'HTTPS', 'TCP', 'UDP', or  'ICMP'."
  type        = string
  default     = "HTTPS"
}

variable "lb_app2_port" {
  description = "Port number for the application to communicate on."
  type        = number
  default     = "443"
}

variable "lb_app2_proto" {
  description = "Application layer protocol 'HTTP', 'HTTPS', 'TCP', 'UDP', or  'ICMP'."
  type        = string
  default     = "HTTPS"
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

variable "lb_sg_vpc_id" {
  description = "Load balancer security group VPC id."
  type        = string
}

variable "lb_app_cidr" {
  description = "A list of CIDR-formatted IP address ranges from which the EC2 Instances will allow connections to Security Group."
  type        = list(string)
}

variable "lb_name" {
  description = "Load balancer name."
  type        = string
}

variable "lb_security_groups" {
  description = "List of security groups attached to the load balancer."
  type        = list(string)
  default     = []
}

variable "lb_subnets" {
  description = "List of subnets attached to the load balancer."
  type        = list(string)
}

variable "lb_tg_name" {
  description = "Name of the load balancer attached to the target group."
  type        = string
}

variable "lb_tg_vpc_id" {
  description = "Id of the vpc for the load balancer target group"
  type        = string
}

variable "load_balancer_type" {
  description = "Type of load balancer to provision, 'application', 'network' or 'none'."
  type        = string
}

variable "tags" {
  description = "A dict of optional tags to be applied to resources created by this module."
  type        = map(string)
  default     = {}
}

variable "vpc_name" {
  description = "Name of VPC to deploy resource into."
  type        = string
  default     = "main"
}
