# Terraform Airflow Platform

A simple AWS infrastructure for running Apache Airflow with Docker.

## 🚀 What It Creates
- 1 VPC (10.0.0.0/16)
- 1 Public Subnet (10.0.1.0/24)
- 1 Security Group (22 + 8080 open)
- 1 EC2 instance for Airflow
- 1 S3 bucket for data storage

## 🧰 How to Use

1. Clone this repository  
   ```bash
   git clone https://github.com/<your-username>/terraform-airflow-platform.git
   cd terraform-airflow-platform
