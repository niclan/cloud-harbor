provider "aws" {
  region = var.region

  default_tags {
    tags = {
      billed-service = "harbor"
      billed-team = "vg-ops"
      terraformed = "https://github.schibsted.io/vg/cloud-harbor"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "mpt-ops-pro-tf-state-bucket"
    key    = "harbor/production"
    region = "eu-north-1"
  }
}

# Provision networking and EC2 instance.
module "ec2-instance" {
  source = "./ec2-instance"
}

# Create DNS record pointing to EC2 instance in Route53.
module "route53-dns" {
  source    = "./route53-dns"
  zone_id   = "Z0131342324XQQ8WM0HG6"
  dns_name  = "harbor.aws.vgnett.no"
  public_ip = module.ec2-instance.public_ip
}

