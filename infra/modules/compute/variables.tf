variable "project_name" {
  description = "Project name"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_id" {
  description = "Security Group ID"
  type        = string
}

variable "key_name" {
  description = "SSH Key Name"
  type        = string
}

variable "private_key_path" {
  description = "Path to the local private SSH key for provisioning"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN of the S3 bucket for IAM policy"
  type        = string
}

variable "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP to associate"
  type        = string
  default     = ""  # Make it optional for fallback, but we intend to use it.
}
