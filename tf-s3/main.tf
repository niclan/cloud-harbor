variable "region" {
  type = string
  default = "eu-north-1"
}

provider "aws" {
  region = var.region

  default_tags {
    tags = {
      billed-service = "docker-registry"
      billed-team = "vg-ops"
      terraformed = "true"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "mpt-ops-pro-tf-state-bucket"
    key    = "harbor/s3"
    region = "eu-north-1"
  }
}

data "aws_caller_identity" "current" {}

resource "aws_iam_user" "s3_user" {
  name = "s3-harbor-user"
}

resource "aws_iam_access_key" "s3_user_key" {
  user = aws_iam_user.s3_user.name
}

resource "aws_iam_user_policy_attachment" "s3_user_policy" {
  user       = aws_iam_user.s3_user.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

output "access_key_id" {
  value = aws_iam_access_key.s3_user_key.id
}

output "access_key_secret" {
  value = aws_iam_access_key.s3_user_key.secret
  sensitive = true
}

data "aws_iam_policy_document" "s3_policy_doc" {
  statement {
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_user.s3_user.arn
      ]
    }
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads"
    ]
    resources = [
      aws_s3_bucket.bucket.arn
    ]
  }

  statement {
    principals {
      type = "AWS"
      identifiers = [
        aws_iam_user.s3_user.arn
      ]
    }
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
      "s3:AbortMultipartUpload"
    ]
    resources = [
      "${aws_s3_bucket.bucket.arn}/*"
    ]
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = aws_s3_bucket.bucket.bucket
  policy = data.aws_iam_policy_document.s3_policy_doc.json
}

resource "aws_s3_bucket" "bucket" {
  bucket = "harbor-reeneepeid9n"
}

## Outputs here

output "s3_bucket" {
  value = aws_s3_bucket.bucket.bucket
}

output "s3_bucket_arn" {
  value = aws_s3_bucket.bucket.arn
}


output "s3_region" {
  value = aws_s3_bucket.bucket.region
}


output "s3_bucket_url" {
  value = "https://${aws_s3_bucket.bucket.bucket}.s3.amazonaws.com"
}
