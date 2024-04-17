output "public_ip" {
  description = "Public IP of EC2 instance"
  value = aws_eip.harbor.public_ip
}

output "public_vpc_id" {
  description = "Public VPC ID"
  value = aws_vpc.public_vpc.id
}

output "subnet_ids" {
  description = "List of subnets"
  value = [aws_subnet.public_subnet_1a.id]
}
