# VPC
resource "aws_vpc" "public_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true

  tags = {
    Name = "harbor-public-vpc"
  }
}

# Subnet
resource "aws_subnet" "public_subnet_1c" {
  availability_zone = "${var.region}c"
  cidr_block = var.subnet1c_cidr
  vpc_id = aws_vpc.public_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "harbor-public-subnet-1c"
  }
}


# Internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.public_vpc.id
  tags = {
    Name = "harbor-igw"
  }
}

# Route table for EC2 instance.
resource "aws_route_table" "default_route" {
  vpc_id = aws_vpc.public_vpc.id

  # Default route over internet gateway.
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_main_route_table_association" "main_route_table" {
  vpc_id = aws_vpc.public_vpc.id
  route_table_id = aws_route_table.default_route.id
}


# Security group for EC2 instance.
resource "aws_security_group" "harbor_sg" {
  name = "harbor_sg"
  description = "Security group for harbor"

  vpc_id = aws_vpc.public_vpc.id

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Appgate SSH access to Harbor EC2 instance."
  }

  # HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP access to Harbor EC2 instance. Must be open to the world because of Letsencrypt challenge."
  }

  # HTTPS
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
    description = "Appgate HTTPS access to Harbor EC2 instance."
  }


  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["195.88.54.0/23"]
    description = "Inbound access from VG data center."
  }

  # Allow all outgoing traffic.
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}



# EC2 instance.
resource "aws_instance" "harbor" {
  instance_type = "t3.medium"   # 4GB RAM, 2 vCPUs
  ami = data.aws_ami.bitnami_harbor.id
  key_name = var.ssh_key
  vpc_security_group_ids = [aws_security_group.harbor_sg.id]
  subnet_id = aws_subnet.public_subnet_1c.id

  user_data = <<-EOF
              #!/bin/bash
              set -e
              export DEBIAN_FRONTEND=noninteractive
              export AWS_DEFAULT_REGION=${var.region}
              apt-get update
              apt-get dist-upgrade -y
              apt-get install -y docker.io
              apt-get install -y docker-compose
              apt-get install -y nginx
              apt-get install -y acmetool
              mkdir -p /var/cinc /root/.cinc

              AWS_ACCESS_KEY_ID=${data.terraform_remote_state.s3_chef_solo.outputs.s3_access_key} \
              AWS_SECRET_ACCESS_KEY=${data.terraform_remote_state.s3_chef_solo.outputs.s3_secret_key} \
                aws s3 cp s3://${data.terraform_remote_state.s3_chef_solo.outputs.s3_bucket}/cinc-repo.tar.gz - | tar -xzC /var/cinc

              ln -s /var/cinc/dot-cinc/knife.rb /root/.cinc/knife.rb

              cinc-solo -o 'role[ec2]'

              EOF

  root_block_device {
    volume_size = 30
  }

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "harbor-production"
    SDP_1839_6408 = "sdp_461479555057"
  }
}

resource "aws_eip" "harbor" {
  domain = "vpc"
  instance = aws_instance.harbor.id
  depends_on = [aws_internet_gateway.igw]

  tags = {
    Name = "harbor-eip"
  }
}
