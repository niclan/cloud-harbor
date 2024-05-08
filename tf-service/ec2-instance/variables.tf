variable "vpc_cidr" {
  type = string
  default = "10.42.0.0/24"
}


variable "subnet1c_cidr" {
  type = string
  default = "10.42.0.0/26"
}


variable "allowed_cidr_blocks" {
  type = list(string)
  default = ["13.48.61.7/32", "13.48.80.55/32", "80.91.33.0/24"]
}

variable "region" {
  type = string
  default = "eu-north-1"
}

variable "ssh_key" {
  type = string
  default = "harbor-init"
}

variable "bastion_user" {
  type = string
  description = "Username for bastion host login"
  default = "admin"
}

data "terraform_remote_state" "s3_chef_solo" {
  # The state bucket is always in eu-north-1
  backend = "s3"
  config = {
    bucket = "mpt-ops-pro-tf-state-bucket"
    key    = "chef-solo/s3"
    region = "eu-north-1"
  }
}

data "aws_ami" "bitnami_harbor" {
  most_recent = true
  owners = ["Bitnami by VMware"]
  filter {
    name = "name"
    values = ["harbor"]
  }
}

