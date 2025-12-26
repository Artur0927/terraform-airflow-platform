terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Networking Module (VPC, Subnets, Security Groups, NAT, ALB)
module "networking" {
  source            = "./modules/networking"
  project_name      = "${var.project_name}-${var.environment}"
  # New Inputs for NAT Instance
  eip_allocation_id = var.eip_allocation_id
  key_name          = var.key_name
}

# 2. Storage Module (S3)
module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

# 3. Compute Module (EC2 Airflow)
module "compute" {
  source            = "./modules/compute"
  project_name      = "${var.project_name}-${var.environment}"
  instance_type     = var.instance_type
  
  # Networking Inputs
  subnet_id         = module.networking.private_subnet_ids[0] # Place in Private Subnet
  security_group_id = module.networking.security_group_private_app_id
  bastion_public_ip = module.networking.nat_public_ip       # For SSH Provisioning
  
  # Instance Inputs
  key_name          = var.key_name
  private_key_path  = var.private_key_path
  
  # Storage Inputs
  s3_bucket_arn     = module.storage.bucket_arn
  s3_bucket_name    = module.storage.bucket_name
}

# 4. ALB Target Group Attachment
resource "aws_lb_target_group_attachment" "airflow_tg_attachment" {
  target_group_arn = module.networking.target_group_arn
  target_id        = module.compute.instance_id
  port             = 8080
}

# Outputs
output "alb_dns_name" {
  description = "Public DNS name of the Application Load Balancer"
  value       = module.networking.alb_dns_name
}

output "nat_bastion_ip" {
  description = "Public IP of the NAT/Bastion Instance (for SSH)"
  value       = module.networking.nat_public_ip
}

output "airflow_private_ip" {
  description = "Private IP of the Airflow Instance"
  value       = module.compute.instance_private_ip
}

output "s3_bucket_name" {
  value = module.storage.bucket_name
}
