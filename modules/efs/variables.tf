variable "efs_subnet" {
  description = "subnet for the efs to deploy to"
  type        = string
}

variable "instance_security_group" {
  description = "Security group of the instance to attach the efs to."
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


variable "app_name" {
  description = "Name of Application"
  type        = string
}