# Terraform Airflow Data Platform 🚀
![Build Status](https://github.com/Artur0927/terraform-airflow-platform/actions/workflows/deploy.yml/badge.svg)

**A Production-Grade, Automated Data Engineering Platform on AWS.**

This project demonstrates a fully automated, **Infrastructure-as-Code (IaC)** deployment of Apache Airflow on AWS. It is engineered to run stably using **Docker Compose** on EC2, with a robust **CI/CD pipeline** for zero-downtime updates.

---

## 🏗 Technical Architecture

### 1. Infrastructure as Code (Terraform)
The project uses a **modular Terraform architecture** for clean separation of concerns and reusability:

-   **`modules/networking`**: Enterprise-grade network topology featuring **Public/Private Subnet isolation**, High-Availability NAT Gateway (Bastion), and Application Load Balancer (ALB).
-   **`modules/storage`**: S3 Bucket provisioning (`airflow-data-platform-{env}-bucket`) for durable data ingestion.
-   **`modules/compute`**: EC2 Instance provisioning with automated lifecycle management via User Data.
-   **Static Egress IP**: Utilizes **AWS Elastic IP (EIP)** to ensure consistent allow-listing capabilities for external APIs.
-   **Security First**: Zero-trust architecture. Airflow runs in a completely isolated private subnet, accessible ONLY via the ALB (Web) or Bastion Tunnel (SSH).

### 2. 🚀 Automated CI/CD Pipeline
The project features a **Zero-Touch Deployment** pipeline powered by GitHub Actions, adhering to GitOps principles.

**Workflow:**
1.  **Code Push** 💻: Developer commits to `main`.
2.  **Infrastructure Plan** 🏗️: Terraform verifies state and plans changes.
3.  **Secure Delivery** 🔐: Changes are deployed via SSH Tunnel through the Bastion Host, ensuring the private instance is never exposed.
4.  **Rolling Update** 🔄: Docker containers are rebuilt and restarted with zero downtime.

### 3. One-Click Provisioning
A single `terraform apply` command orchestrates the entire stack:
1.  **Network Application**: VPC, Subnets, Route Tables, IGW.
2.  **Server Bootstrapping**: Amazon Linux 2023 initialization with Docker engine optimization.
3.  **Application Startup**: Airflow, Postgres, and Monitoring stack initialization.

---

## 🔒 Security
All sensitive infrastructure keys and secrets are managed via **GitHub Secrets** and **Terraform Variables**.
-   **No Hardcoded Secrets**: `.env` files and `*.pem` keys are git-ignored.
-   **IAM Roles**: Used for AWS Service authentication (S3).
-   **Network Isolation**: Airflow runs in a Private Subnet, accessible only via a hardened Bastion Host.

---

## 💡 Key Engineering Challenges Solved

### 1. Memory Optimization
*   **Challenge**: Running the full Airflow stack (Webserver, Scheduler, Postgres) on a budget instance.
*   **Solution**: We upgraded to **`t3.small` (2GB RAM)** and tuned Airflow parameters (`AIRFLOW__WEBSERVER__WORKERS=2`, `AIRFLOW__CORE__PARALLELISM=2`) to maximize performance without crashing. We also utilize a **2GB Swap File** as a safety net.

### 2. Automated Database Initialization
*   **Challenge**: Docker containers would start but crash immediately because the Postgres database schema and Admin user were missing.
*   **Solution**: Implemented a custom `airflow-init` service in `docker-compose.yaml` that runs **before** the webserver to:
    -   Execute `airflow db migrate` (Schema Creation).
    -   Create the default `airflow` Admin user.
    -   **Dynamic Configuration**: Automatically injects S3 Bucket names into the Airflow Database on startup.

### 3. Permission & Security
*   **Challenge**: `Permission Denied` errors when Airflow (UID 50000) tried to write logs to host-mounted volumes owned by root.
*   **Solution**: The deployment script automatically pre-creates `logs`, `dags`, and `plugins` directories with **UID 50000 ownership** before starting containers.

---

## 🚀 Deployment Guide

### Prerequisites
-   **Terraform** installed.
-   **AWS Credentials** configured.
-   **SSH Key Pair**: You must provide the path to your private key.

### 1. Deploy to Production
To provision the infrastructure and start the application:

```bash
cd infra
terraform apply -var-file="prod.tfvars" -var="private_key_path=/path/to/your/key.pem"
```

*Replace `/path/to/your/key.pem` with your actual private key location (e.g., `~/.ssh/id_rsa`).*

### 2. Access the Platform
Once applied, the infrastructure will be fully operational.
-   **Web Interface**: Access via the **Application Load Balancer** (ALB) URL output by Terraform.
    -   *URL*: `http://<ALB_DNS_NAME>` (Standard HTTP)
    -   *Credentials*: Defined in `.env` (Default: `airflow` / `airflow`)

### 3. Destruction (Cost Management)
To decommission the environment and prevent recurring costs:

```bash
terraform destroy -var-file="prod.tfvars" -var="private_key_path=/path/to/your/key.pem"
```

---

## 📂 Project Structure

```
terraform-airflow-platform/
├── .github/workflows/          # CI/CD Pipelines
│   └── deploy.yml              # Automated Deployment Script
├── infra/                      # Terraform Infrastructure
│   ├── modules/
│   │   ├── networking/         # VPC, Subnets, Security Groups
│   │   ├── storage/            # S3 Buckets
│   │   └── compute/            # EC2, IAM Roles, EIP, User Data
│   ├── dev.tfvars              # Development Configuration
│   ├── prod.tfvars             # Production Configuration
│   └── main.tf                 # Root Module Orchestration
│
├── airflow/                    # Application Code
│   ├── docker-compose.yaml     # Airflow Service Definition (with Init)
│   └── dags/                   # ELT Pipelines (Python)
│
└── README.md
```

## 🛠 Technologies Used
-   **Terraform** (IaC, Modules, Provisioners)
-   **AWS** (EC2, VPC, S3, IAM, EIP, Security Groups)
-   **GitHub Actions** (CI/CD)
-   **Docker & Docker Compose**
-   **Apache Airflow 2.9.2**
-   **PostgreSQL 15**
-   **Python** (Boto3, Psycopg2)
-   **Bash** (Automation Scripts)

---
**Author**: Artur Martirosyan
