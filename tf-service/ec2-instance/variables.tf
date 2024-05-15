variable "vpc_cidr" {
  type = string
  default = "10.42.0.0/24"
}

variable "subnet1c_cidr" {
  type = string
  default = "10.42.0.0/26"
}


variable "allowed_cidr_blocks_registry" {
  type = list(string)
  default = [
    "13.48.61.7/32", "13.48.80.55/32", # Appgate
    "80.91.33.0/24", # VG data center
    "13.49.209.19/32", "13.51.155.50/32", "16.170.78.245/32", # Developer foundations Github runners
    "16.170.160.240/32", "51.20.112.181/32", "51.20.179.2/32", # vg-lab-pro-1
    "35.189.224.153/32", "35.195.116.134/32", "35.195.87.41/32" # vg-ops-pro-1
  ]
}


variable "allowed_cidr_blocks_ssh" {
  type = list(string)
  default = [
    "13.48.61.7/32", "13.48.80.55/32", # Appgate
    "80.91.33.0/24" # VG data center
  ]
}

variable "region" {
  type = string
  default = "eu-north-1"
}

variable "ssh_key" {
  type = string
  default = "harbor-init"
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

data "terraform_remote_state" "s3_harbor" {
  # The state buckets are always in eu-north-1
  backend = "s3"
  config = {
    bucket = "mpt-ops-pro-tf-state-bucket"
    key    = "harbor/s3"
    region = "eu-north-1"
  }
}

data "aws_ami" "debian" {
  most_recent = true
  owners = ["136693071363"]
  filter {
    name = "name"
    values = ["debian-12-amd64-*"]
  }
}
