provider "aws" {
  region = var.region
}

# Tạo VPC
resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "DevOps-VPC"
  }
}
resource "aws_default_tags" "default" {
  tags = {
    Environment = "DevOps"
    Owner       = "tuhoang"
  }
}
# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_cidr
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "Public-Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_cidr
  availability_zone = "us-east-1a"
  tags = {
    Name = "Private-Subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Internet-Gateway"
  }
}

# NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
  tags = {
    Name = "NAT-Gateway"
  }
}

# Route Tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Public-Route-Table"
  }
}

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Private-Route-Table"
  }
}

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Security Groups
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip] # Dùng biến thay IP cứng
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Cần nếu chạy HTTP server
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "Public-SG"
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    security_groups  = [aws_security_group.public_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Private-SG"
  }
}


# EC2 Instances
resource "aws_instance" "public_ec2" {
  ami                        = "ami-0c02fb55956c7d316"  # Amazon Linux 2 AMI (US-East-1)
  instance_type              = "t2.micro"
  subnet_id                  = aws_subnet.public.id
  vpc_security_group_ids     = [aws_security_group.public_sg.id]  # Use security group ID here
  associate_public_ip_address = true
  depends_on = [aws_security_group.public_sg]  # Ensure security group is created first
  tags = {
    Name = "Public-EC2"
  }
}

resource "aws_instance" "private_ec2" {
  ami           = var.ami_id
  instance_type              = "t2.micro"
  subnet_id                  = aws_subnet.private.id
  vpc_security_group_ids     = [aws_security_group.private_sg.id]  # Use security group ID here
  depends_on = [aws_security_group.private_sg]  # Ensure security group is created first
  tags = {
    Name = "Private-EC2"
  }
}
