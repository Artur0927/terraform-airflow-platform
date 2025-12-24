resource "aws_instance" "airflow_ec2" {
  ami                         = "ami-0c02fb55956c7d316"
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = true
  key_name                    = var.key_name
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name

  metadata_options {
    http_put_response_hop_limit = 2
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
  }

  # User Data: Install Docker & Compose
  user_data = file("${path.module}/setup.sh")

  # Connection for Provisioners
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file(var.private_key_path)
    host        = self.public_ip
  }

  # 1. Create Directory
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ec2-user/airflow"
    ]
  }

  # 2. Upload Airflow Directory
  provisioner "file" {
    source      = "${path.root}/../airflow/"
    destination = "/home/ec2-user/airflow"
  }

  # 2. Start Application
  provisioner "remote-exec" {
    inline = [
      "echo 'Waiting for cloud-init to finish...'",
      "while [ ! -f /usr/local/bin/docker-compose ]; do sleep 5; done", # Wait for User Data
      "cd /home/ec2-user/airflow",
      "echo 'AIRFLOW_VAR_S3_BUCKET_NAME=${var.s3_bucket_name}' > .env",
      "mkdir -p logs plugins dags",
      "sudo chown -R 50000:0 logs plugins dags",
      "sudo chmod -R 777 logs plugins dags",
      "sudo /usr/local/bin/docker-compose up -d"
    ]
  }

  tags = {
    Name = "${var.project_name}-ec2"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.airflow_ec2.id
  allocation_id = var.eip_allocation_id
}

data "aws_eip" "by_id" {
  id = var.eip_allocation_id
}
