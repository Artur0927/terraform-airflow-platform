resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# --- Public Subnets (ALB & NAT) ---
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = { Name = "${var.project_name}-public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"

  tags = { Name = "${var.project_name}-public-subnet-2" }
}

# --- Private Subnets (App) ---
resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = { Name = "${var.project_name}-private-subnet-1" }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = { Name = "${var.project_name}-private-subnet-2" }
}

# --- NAT Instance (Router & Bastion) ---
resource "aws_security_group" "sg_nat_bastion" {
  name        = "${var.project_name}-nat-bastion-sg"
  description = "Security Group for NAT Instance and Bastion"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "SSH from Admin"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # In production, restrict to Admin IP!
  }

  ingress {
    description = "All Traffic from VPC (for NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "All Outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-nat-bastion-sg" }
}

resource "aws_instance" "nat_bastion" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2023
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet_1.id # Public Subnet
  vpc_security_group_ids      = [aws_security_group.sg_nat_bastion.id]
  key_name                    = var.key_name
  source_dest_check           = false # Crucial for NAT!
  associate_public_ip_address = true # Will be overridden by EIP, but good to have

  user_data = <<-EOF
              #!/bin/bash
              sysctl -w net.ipv4.ip_forward=1
              echo "net.ipv4.ip_forward=1" >> /etc/sysctl.conf
              yum install -y iptables-services
              iptables -t nat -A POSTROUTING -o enX0 -j MASQUERADE
              iptables -t nat -A POSTROUTING -o ens5 -j MASQUERADE
              iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
              service iptables save
              systemctl enable iptables
              systemctl start iptables
              EOF

  tags = { Name = "${var.project_name}-nat-bastion" }
}

# --- Associate Persistent EIP with NAT Instance ---
data "aws_eip" "by_id" {
  id = var.eip_allocation_id
}

resource "aws_eip_association" "nat_eip_assoc" {
  instance_id         = aws_instance.nat_bastion.id
  allocation_id       = var.eip_allocation_id
  allow_reassociation = true
}

# --- Route Tables ---
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project_name}-public-rt" }
}

resource "aws_route_table_association" "public_assoc_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.public_rt.id
}
resource "aws_route_table_association" "public_assoc_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block           = "0.0.0.0/0"
    network_interface_id = aws_instance.nat_bastion.primary_network_interface_id
  }
  tags = { Name = "${var.project_name}-private-rt" }
}

resource "aws_route_table_association" "private_assoc_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_rt.id
}
resource "aws_route_table_association" "private_assoc_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_rt.id
}

# --- Load Balancer (ALB) ---
resource "aws_security_group" "sg_alb" {
  name        = "${var.project_name}-alb-sg"
  description = "Security Group for ALB"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description = "HTTP from Internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Outbound to VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
  tags = { Name = "${var.project_name}-alb-sg" }
}

resource "aws_lb" "app_alb" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.sg_alb.id]
  subnets            = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
  tags               = { Name = "${var.project_name}-alb" }
}

resource "aws_lb_target_group" "app_tg" {
  name     = "${var.project_name}-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main_vpc.id
  health_check {
    path                = "/health"
    port                = "8080"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# --- App Security Group (Private EC2) ---
resource "aws_security_group" "sg_private_app" {
  name        = "${var.project_name}-private-app-sg"
  description = "Security Group for Private Airflow Instance"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    description     = "HTTP from ALB"
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_alb.id]
  }

  ingress {
    description     = "SSH from Bastion"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.sg_nat_bastion.id]
  }

  egress {
    description = "All Outbound (via NAT)"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = { Name = "${var.project_name}-private-app-sg" }
}
