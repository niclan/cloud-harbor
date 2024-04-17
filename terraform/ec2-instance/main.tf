# VPC
resource "aws_vpc" "public_vpc" {
  cidr_block = "10.42.0.0/24"
  enable_dns_hostnames = true

  tags = {
    Name = "harbor-public-vpc"
  }
}

# Subnet
resource "aws_subnet" "public_subnet_1a" {
  availability_zone = "eu-north-1a"
  cidr_block = "10.42.0.0/26"
  vpc_id = aws_vpc.public_vpc.id
  map_public_ip_on_launch = true

  tags = {
    Name = "harbor-public-subnet-1a"
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


resource "aws_security_group" "harbor_efs_sg" {
  name = "harbor_efs_sg"
  description = "Security group for harbor EFS"

  vpc_id = aws_vpc.public_vpc.id

  # NFS
  ingress {
    from_port = 2049
    to_port = 2049
    protocol = "tcp"
    cidr_blocks = [aws_vpc.public_vpc.cidr_block]
    description = "NFS access to Harbor EFS."
  }
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
    cidr_blocks = ["13.48.61.7/32", "13.48.80.55/32", "80.91.33.0/24"]
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
    cidr_blocks = ["13.48.61.7/32", "13.48.80.55/32", "80.91.33.0/24"]
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


resource "aws_efs_file_system" "harbor_application_storage" {
  creation_token = "harbor-application-storage"
  encrypted = true
  performance_mode = "generalPurpose"
  tags = {
    Name = "harbor-application-storage"
  }
}


resource "aws_efs_mount_target" "harbor_application_mount_target_eu_north_1a" {
  file_system_id = aws_efs_file_system.harbor_application_storage.id
  subnet_id = aws_subnet.public_subnet_1a.id
  security_groups = [aws_security_group.harbor_efs_sg.id]
}


# EC2 instance.
resource "aws_instance" "harbor" {
  instance_type = "t3.medium"   # 4GB RAM, 2 vCPUs
  ami = "ami-0506d6d51f1916a96" # Debian 12
  key_name = var.ssh_key
  vpc_security_group_ids = [aws_security_group.harbor_sg.id]
  subnet_id = aws_subnet.public_subnet_1a.id

  root_block_device {
    volume_size = 30
  }

  metadata_options {
    http_tokens = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "harbor-production"
    # SDP_1737_5957 = "sdp_070941167498" # AppGate TODO, add appgate tag
  }

  connection {
    type = "ssh"
    user = "admin"
    host = self.public_ip
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get dist-upgrade -y",
      "sudo apt-get install -y docker.io",
      "sudo apt-get install -y docker-compose",
      "sudo apt-get install -y nfs-common",
      "sudo mkdir -p /services/harbor",
      "echo ${aws_efs_file_system.harbor_application_storage.dns_name}:/ /services/harbor nfs4 nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2,norecvport,nofail 0 0 | sudo tee -a /etc/fstab",
      "sudo mount /services/harbor"
    ]
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

