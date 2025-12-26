variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
}

variable "eip_allocation_id" {
  description = "Allocation ID of the persistent Elastic IP for the NAT Instance"
  type        = string
}

variable "key_name" {
  description = "Name of the SSH key pair for the NAT Bastion"
  type        = string
}
