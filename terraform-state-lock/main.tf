provider "aws" {
   region     = "us-east-1"
   access_key = var.access_key  #store the access key and secret key in the variables.tf file
   secret_key = var.secret_key
}

# VPC Configuration (Public VPC)
resource "aws_vpc" "public_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "Public_VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.public_vpc.id

  tags = {
    Name = "public_vpc_igw"
  }
}

# Subnet Configuration (Public Subnet)
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.public_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"  # Change to your preferred availability zone
  map_public_ip_on_launch = true
  tags = {
    Name = "public_subnet"
  }
}

# Create Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.public_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "public_rta" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group Configuration (sg1)
resource "aws_security_group" "sg1" {
  name        = "sg1"
  description = "Security group allowing HTTP, ICMP, and SSH"
  vpc_id      = aws_vpc.public_vpc.id

  # Allow HTTP (Port 80)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow ICMP (Ping)
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow SSH (Port 22)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Outbound Rules (allow all outbound)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Key Pair for EC2 SSH Access
resource "aws_key_pair" "web_key_pair" {
  key_name   = "web_key_pair"
  public_key = file("./aws1.pub")  # Adjust path if needed
}

# EC2 Instance Configuration (web_server)
resource "aws_instance" "web_server" {
  ami                    = "ami-0c614dee691cbbf37"  # Replace with the AMI ID for your region
  instance_type          = "t2.micro"               # Adjust instance type as needed
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.sg1.id]
  key_name               = aws_key_pair.web_key_pair.key_name  # Use the key pair

  tags = {
    Name = "web_server_new"
  }
}

terraform {
    backend "s3" {
        bucket = "henokk-terraform-s3-bucket"  #create this bucket
        key    = "henok/terraform/remote/s3/terraform.tfstate"
        region     = "us-east-1"
        dynamodb_table = "dynamodb-state-locking" #create this dynamodb table with partition key = LockID
    }
}
