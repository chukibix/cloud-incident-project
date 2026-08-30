// The VPC 10.0.0.0/16, has 3 subnets, 2 pub, 1 private.
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

// Public subnet , hosts the EC2 instance, routes out to the internet via the IGW
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block               = "10.0.1.0/24"
  availability_zone        = "eu-west-3a"
  map_public_ip_on_launch  = false // matches original setup — public IP comes from the EIP instead

  tags = {
    Name = "${var.project_name}-public-subnet"
  }
}

// Private subnet A (eu-west-3a), used by RDS
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "eu-west-3a"

  tags = {
    Name = "${var.project_name}-private-subnet-a"
  }
}

// Private subnet B (eu-west-3b), required so RDS can span 2 AZs for its subnet group
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "eu-west-3b"

  tags = {
    Name = "${var.project_name}-private-subnet-b"
  }
}

// Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

// Route table for the public subnet: sends all outbound traffic through the IGW
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

// Links the public subnet to the public route table 
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

// get own ip, to use for SG
data "http" "my_ip" {
  url = "https://ifconfig.me/ip"
}

// Security group for the EC2 instance
resource "aws_security_group" "ec2_sg" {
  name        = "cloud-incident-ec2-sg"
  description = "Security group for EC2 Kubernetes host"
  vpc_id      = aws_vpc.main.id

  // Inbound: SSH (port 22), locked to my pc
  ingress {
    description = "SSH from admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.my_ip.response_body)}/32"]
  }

  // Outbound: unrestricted — instance can reach anything
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  //acces from internet
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud-incident-ec2-sg"
  }
}

// Security group for RDS — only reachable from the EC2 security group, not the open internet
resource "aws_security_group" "rds_sg" {
  name        = "cloud-incident-rds-sg"
  description = "Security group for RDS Postgres"
  vpc_id      = aws_vpc.main.id

  // Inbound: Postgres (port 5432), only from instances in the ec2_sg group
  ingress {
    description     = "Postgres from EC2 SG"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cloud-incident-rds-sg"
  }
}

// The EC2 instance — runs Kubernetes, which hosts Grafana/Prometheus
resource "aws_instance" "k8s" {
  ami                    = "ami-0e1c4170d9c01184b"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  key_name               = "cloud-incident-key"
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.instance_profile.name
  
  //install k8s + Grafana + Prometheus on boot.
  user_data = templatefile("${path.module}/scripts/user_data.sh.tpl", {
    db_password  = var.db_password
    db_name      = var.db_name
    ecr_repo_url = var.ecr_repo_url
  })

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "cloud-incident-k8s"
  }
}

// fixed public IP 
resource "aws_eip" "k8s" {
  instance = aws_instance.k8s.id
  domain   = "vpc"

  tags = {
    Name = "${var.project_name}-k8s-eip"
  }
}

// DB subnet group , 2 az
resource "aws_db_subnet_group" "main" {
  name        = "clou-incident- project" // exact existing name, kept as-is (typo/space included)
  subnet_ids  = [aws_subnet.private_a.id, aws_subnet.private_b.id]
  description = "for projrct purposes,  my db to span in 2 az"

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

// The RDS Postgres database instance itself
resource "aws_db_instance" "main" {
  identifier              = "cloud-incident-db"
  engine                  = "postgres"
  engine_version           = "18.3"
  instance_class          = "db.t4g.micro"
  allocated_storage       = 20
  db_subnet_group_name    = aws_db_subnet_group.main.name
  vpc_security_group_ids  = [aws_security_group.rds_sg.id]
  publicly_accessible     = false // not reachable from the open internet, only from within the VPC
  multi_az                = false // single availability zone, no automatic failover replica

  username             = "postgres"
  password              = var.db_password // pulled from terraform.tfvars, never hardcoded here
  skip_final_snapshot   = true // no backup taken on destroy — fine for disposable/test use
}