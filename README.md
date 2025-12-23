# Terraform Airflow Data Platform

This project demonstrates a **production-style data platform on AWS**, combining **Infrastructure as Code** with **Apache Airflow–based data orchestration**.

The goal of the project is to showcase a realistic **end-to-end workflow** —  
from secure infrastructure provisioning to data ingestion and orchestration.

---

## Project Overview

The platform consists of:

- AWS infrastructure provisioned using **Terraform**
- An **EC2-based execution environment**
- **Apache Airflow** running in Docker
- **PostgreSQL** used as a target database
- **AWS S3** as a source for raw data
- Secure access via **IAM Roles and STS** (no static credentials)

The project follows a clear **separation of concerns** between infrastructure provisioning and application-level configuration, reflecting common real-world practices.

---

## Infrastructure Provisioning

Infrastructure is defined using **Terraform** and includes:

- Virtual Private Cloud (VPC)
- Public Subnet and routing
- Security Groups
- EC2 instance
- IAM Role for secure AWS access
- S3 bucket for raw data storage

Terraform is responsible for creating a **reproducible execution environment** in AWS.

The infrastructure code represents the **intended system design** and can be used to recreate the environment from scratch.

---

## SSH Access and Key Management

Secure access to the EC2 instance is implemented using **SSH key-based authentication**.

### Key Generation

- An SSH key pair was generated locally on the developer machine using `ssh-keygen`
- The private key is stored securely on the local machine and never shared
- The public key is used to allow access to the EC2 instance

### Usage

- The public key is associated with the EC2 instance
- SSH access is performed using the private key from the local machine
- Password-based authentication is disabled, following security best practices

This approach ensures **secure and auditable access** to the infrastructure without relying on passwords.

---

## Security and Authentication

AWS access is implemented using **IAM Roles**, not static credentials.

- An IAM Role with S3 permissions is attached to the EC2 instance
- Applications use **AWS STS temporary credentials** obtained via the EC2 metadata service
- No AWS access keys or secrets are stored in code, configuration files, or environment variables

This reflects **AWS best practices** for secure, production-grade authentication.

---

## Application Layer

Application setup is performed **on top of the provisioned infrastructure** and includes:

- Docker and Docker Compose installation
- Apache Airflow deployment
- PostgreSQL configuration
- Network configuration between services

The application layer is intentionally separated from infrastructure provisioning to mirror **common production workflows**, where infrastructure and application lifecycle are managed independently.

---

## Data Pipeline

The Airflow DAG implements the following workflow:

1. Read a CSV file from an S3 bucket
2. Download data using IAM Role authentication (STS)
3. Create target tables in PostgreSQL
4. Load data using `COPY FROM STDIN`
5. Validate successful data ingestion

The pipeline demonstrates a typical **ELT pattern** used in data engineering projects.

---

## 📸 Screenshots

The following screenshots provide a visual overview of the platform,
from infrastructure provisioning to successful data ingestion.

### AWS EC2 Instance

EC2 instance provisioned with Terraform and used as the execution environment
for Apache Airflow and related services.

![AWS EC2 instance](images/AWS%20ES2%20instance.png)

---

### Apache Airflow DAG Graph

DAG dependency graph in Apache Airflow, illustrating the ELT workflow structure.

![Airflow DAG graph](images/Airflow%20dag%20graph.png)

---

### Apache Airflow DAG Runs

Successful DAG runs confirming correct orchestration and execution.

![Airflow DAG runs](images/Airflow%20dag%20runs.png)

---

### PostgreSQL Data

Data successfully loaded into PostgreSQL as a result of the ELT pipeline.

![Postgres data](images/Postgres%20data.png)

---

## Project Structure


terraform-airflow-platform/
├── infra/                  # Terraform infrastructure
│   ├── main.tf
│   ├── variables.tf
│   └── terraform.lock.hcl
│
├── airflow/                # Airflow runtime
│   ├── docker-compose.yaml
│   └── dags/
│       └── elt_s3_to_postgres.py
│
├── images/                 # Project screenshots
│   ├── Airflow dag graph.png
│   ├── Airflow dag runs.png
│   ├── AWS ES2 instance.png
│   └── Postgres data.png
│
├── README.md
└── .gitignore

## Technologies Used

- **Terraform**
- **AWS** (EC2, VPC, S3, IAM, STS)
- **Apache Airflow**
- **Docker & Docker Compose**
- **PostgreSQL**
- **Python** (`boto3`, `psycopg2`)
- **SSH** (key-based authentication)

---

## Key Concepts Demonstrated

- Infrastructure as Code
- Secure SSH access and key management
- IAM Roles and temporary credentials
- Separation of infrastructure and application layers
- Production-style Airflow deployment
- End-to-end ELT pipeline design

---

## Summary

This project reflects a **realistic engineering workflow** where:

- Infrastructure is provisioned declaratively
- Security is handled using cloud-native best practices
- Application services are deployed in a controlled execution environment
- Data pipelines are orchestrated using Apache Airflow

The repository is designed to be **clear, reproducible, and representative of real-world data platform engineering**.

---

## Author

**Artur Martirosyan**



