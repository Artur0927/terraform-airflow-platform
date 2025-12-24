# Terraform Airflow Data Platform 🚀

**A Production-Grade, Automated Data Engineering Platform on AWS.**

This project demonstrates a fully automated, **Infrastructure-as-Code (IaC)** deployment of Apache Airflow on AWS. It is engineered to run stably using **Docker Compose** on EC2, with a robust **CI/CD pipeline** for zero-downtime updates.

---

## 🏗 Technical Architecture

### 1. Infrastructure as Code (Terraform)
The project uses a **modular Terraform architecture** for clean separation of concerns and reusability:

-   **`modules/networking`**: VPC, Public Subnet, Internet Gateway, Route Tables, Security Groups (Ports 22, 8080).
-   **`modules/storage`**: S3 Bucket provisioning (`airflow-data-platform-{env}-bucket`) for data ingestion.
-   **`modules/compute`**: EC2 Instance provisioning with integrated **User Data** automation.
-   **Permanent Static IP**: Uses **AWS Elastic IP (EIP)** to ensure the application IP (`98.80.31.243`) never changes, even if the infrastructure is destroyed and recreated.
-   **Security**: Uses **IAM Roles** (Instance Profiles) for secure S3 access, avoiding hardcoded AWS Keys.

### 2. CI/CD Pipeline (GitHub Actions)
A fully automated deployment pipeline is implemented in `.github/workflows/deploy.yml`:
-   **Trigger**: Runs automatically on every `git push` to `main`.
-   **Action**: SSHs into the EC2 instance, pulls the latest code, and seamlessly restarts the Docker containers.
-   **Auto-Healing**: Automatically detects if the repository is missing on the server and clones it if necessary.

### 3. Full-Stack Automation ("One-Click Deployment")
Running `terraform apply` performs the entire end-to-end setup without manual intervention:
1.  **Provisioning**: Boots an Amazon Linux 2023 server.
2.  **Configuration**: Automatically installs Docker and Docker Compose via `user_data` scripts.
3.  **Deployment**: Uploads Airflow DAGs and Configs.
4.  **Startup**: Launch the application using `remote-exec` and auto-generates `.env` files for configuration.

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
Once applied, Terraform will output the public IP.
-   **Web UI**: `http://98.80.31.243:8080`
-   **Login**: `airflow` / `airflow`

### 3. Destroy (Cost Savings)
When finished, strictly follow the **Destroy-Before-Create** workflow to avoid costs:

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
