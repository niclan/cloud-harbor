resource "aws_route53_record" "harbor" {
  zone_id = var.zone_id
  name    = var.dns_name
  type    = "A"
  ttl     = 300
  records = [var.public_ip]
}
