terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}



# create the VPC for all resources
resource "aws_vpc" "info_stealer_c2_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    Name = "info-stealer-c2-vpc"
  }
}

# create the subnet for the victim network
resource "aws_subnet" "victim_network_subnet" {
  vpc_id            = aws_vpc.info_stealer_c2_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = var.az

  tags = {
    Name = "victim_network-subnet"
  }
}

# create the subnet for the attacker
resource "aws_subnet" "attacker_subnet" {
  vpc_id            = aws_vpc.info_stealer_c2_vpc.id
  cidr_block        = "172.16.20.0/24"
  availability_zone = var.az

  tags = {
    Name = "attacker-subnet"
  }
}

# create the security group for the victim VM
resource "aws_security_group" "victim_sg" {
  name        = "victim-sg"
  description = "Security group for the victim vm"
  vpc_id      = aws_vpc.info_stealer_c2_vpc.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr] # your IP CIDR block for SSH access
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "victim-sg"
  }
}

# create the security group for the Wazuh VM
resource "aws_security_group" "wazuh_sg" {
  name        = "wazuh-sg"
  description = "Security group for the Wazuh vm"
  vpc_id      = aws_vpc.info_stealer_c2_vpc.id
  ingress {
    from_port   = 1514 # default port for syslog
    to_port     = 1515
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.victim_network_subnet] # allow access from the victim subnet
  }
  ingress {
    from_port   = 514 # another common syslog port
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.victim_network_subnet] # allow access from the victim subnet
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr] # your IP CIDR block for SSH access
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "wazuh-sg"
  }
}

# create the security group for the attacker VM
resource "aws_security_group" "attacker_sg" {
  name        = "attacker-sg"
  description = "Security group for the attacker vm"
  vpc_id      = aws_vpc.info_stealer_c2_vpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip_cidr] # your IP CIDR block for SSH access
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "attacker-sg"
  }
}

# create the Internet Gateway attached to the VPC
resource "aws_internet_gateway" "info_stealer_c2_igw" {
  vpc_id = aws_vpc.info_stealer_c2_vpc.id

  tags = {
    Name = "info-stealer-c2-igw"
  }
}

# create the Route Table for the victim network subnet
resource "aws_route_table" "victim_network_public_rt" {
  vpc_id = aws_vpc.info_stealer_c2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.info_stealer_c2_igw.id
  }

  tags = {
    Name = "victim-network-public-rt"
  }
}

# associate the Route Table with the public subnet
resource "aws_route_table_association" "victim_network_public_assoc" {
  subnet_id      = aws_subnet.victim_network_subnet.id
  route_table_id = aws_route_table.victim_network_public_rt.id
}

# create the Route Table for the attacker subnet
resource "aws_route_table" "attacker_public_rt" {
  vpc_id = aws_vpc.info_stealer_c2_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.info_stealer_c2_igw.id
  }

  tags = {
    Name = "attacker-public-rt"
  }
}

# associate the Route Table with the attacker subnet
resource "aws_route_table_association" "attacker_public_assoc" {
  subnet_id      = aws_subnet.attacker_subnet.id
  route_table_id = aws_route_table.attacker_public_rt.id
}


# create the EC2 instances for the victim and attacker environments

resource "aws_instance" "vm_victim" {
  ami                         = var.ami_id
  instance_type               = var.vm_type
  subnet_id                   = aws_subnet.victim_network_subnet.id
  vpc_security_group_ids      = [aws_security_group.victim_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name        = "vm-victim"
    description = "This VM hosts the 'Enterprise PC' that the attacker will try to exploit"
  }
}

resource "aws_instance" "vm_wazuh" {
  ami                         = var.ami_id
  instance_type               = var.vm_type
  subnet_id                   = aws_subnet.victim_network_subnet.id
  vpc_security_group_ids      = [aws_security_group.wazuh_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  root_block_device {
    volume_size = 12 # add 4 GB because of the wazuh
    volume_type = "gp3"
  }

  tags = {
    Name        = "vm-wazuh"
    description = "This VM will have the Wazuh Manager installed to monitor the victim VM"
  }
}

resource "aws_instance" "vm_attacker" {
  ami                         = var.ami_id
  instance_type               = var.vm_type
  subnet_id                   = aws_subnet.attacker_subnet.id
  vpc_security_group_ids      = [aws_security_group.attacker_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name        = "vm-attacker"
    description = "This VM is used by the attacker to perform the information stealing attack"
  }
}





# VARIABLES

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "az" {
  type    = string
  default = "us-east-1a"
}

variable "vm_type" {
  type    = string
  default = "t2.micro"
}

variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
  default     = "ami-020cba7c55df1f615" # Ubuntu Server 24.04 LTS (HVM),EBS General Purpose (SSD) AMI for us-east-1
}

variable "key_name" {
  description = "Name of the SSH key pair you created in AWS to use for the EC2 instance"
  type        = string
}

variable "my_ip_cidr" {
  description = "Your IP address in CIDR notation"
  type        = string
}