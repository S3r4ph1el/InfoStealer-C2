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

# create the security group for the victims VM
resource "aws_security_group" "victim_sg" {
  name        = "victim-sg"
  description = "Security group for the victim vm"
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
    cidr_blocks = [aws_subnet.victim_network_subnet.cidr_block] # allow access from the victim subnet
  }
  ingress {
    from_port   = 514 # another common syslog port
    to_port     = 514
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.victim_network_subnet.cidr_block] # allow access from the victim subnet
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
    from_port   = 80
    to_port     = 80
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