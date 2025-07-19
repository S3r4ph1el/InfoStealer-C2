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
    description = "This VM hosts the unsafe PC that the attacker will try to exploit"
  }
}

resource "aws_instance" "vm_protected" {
  ami                         = var.ami_id
  instance_type               = var.vm_type
  subnet_id                   = aws_subnet.victim_network_subnet.id
  vpc_security_group_ids      = [aws_security_group.victim_sg.id]
  associate_public_ip_address = true
  key_name                    = var.key_name

  tags = {
    Name        = "vm-protected"
    description = "This VM hosts the safe PC that the attacker will try to exploit"
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
    volume_size = 30 # add extra disk storage to Wazuh
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