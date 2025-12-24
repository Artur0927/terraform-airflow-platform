provider "aws" {
  region = var.aws_region
}

module "networking" {
  source       = "./modules/networking"
  project_name = var.project_name
}

module "storage" {
  source       = "./modules/storage"
  project_name = var.project_name
  environment  = var.environment
}

module "compute" {
  source            = "./modules/compute"
  project_name      = var.project_name
  instance_type     = var.instance_type
  key_name          = var.key_name
  subnet_id         = module.networking.subnet_id
  security_group_id = module.networking.security_group_id
  private_key_path  = var.private_key_path
  s3_bucket_arn     = module.storage.bucket_arn
  eip_allocation_id = var.eip_allocation_id
}

output "ec2_public_ip" {
  value = module.compute.public_ip
}

output "ec2_public_dns" {
  value = module.compute.public_dns
}

output "s3_bucket_name" {
  value = module.storage.bucket_name
}
