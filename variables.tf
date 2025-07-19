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