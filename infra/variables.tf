#############################################
# Terraform variables
#############################################

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for resources"
  type        = string
  default     = "airflow-data-platform"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, prod)"
  type        = string
  default     = "dev"
}

variable "instance_type" {
  description = "Type of EC2 instance to launch"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of existing SSH key pair in AWS"
  type        = string
  default     = "airflow-data-platform-key"
}

variable "private_key_path" {
  description = "Path to the local private SSH key (e.g., ~/.ssh/id_rsa)"
  type        = string
}

variable "eip_allocation_id" {
  description = "Allocation ID of the Elastic IP to associate"
  type        = string
  default     = ""
}
