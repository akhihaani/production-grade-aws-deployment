# S3 Bucket + DynamoDB for tfstate

resource "aws_s3_bucket" "memos_state" {
  bucket = "memos-tfstate-${var.account_id}"

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "memos_state_versioning" {
  bucket = aws_s3_bucket.memos_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "memos_state_encryption" {
  bucket = aws_s3_bucket.memos_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "memos_state_public_block" {
  bucket                  = aws_s3_bucket.memos_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "memos_locks" {
  name         = "terraform-state-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.tags
}

# S3 bucket for logs

resource "aws_s3_bucket" "memos_lb_logs_bucket_id" {
  bucket = "memos-lb-logs-${var.account_id}"

  tags = local.tags
}

resource "aws_s3_bucket_versioning" "memos_lb_logs_versioning" {
  bucket = aws_s3_bucket.memos_lb_logs_bucket_id.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "memos_lb_logs_encryption" {
  bucket = aws_s3_bucket.memos_lb_logs_bucket_id.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "memos_lb_logs_public_block" {
  bucket                  = aws_s3_bucket.memos_lb_logs_bucket_id.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_policy" "lb_logs_policy" {
  bucket = aws_s3_bucket.memos_lb_logs_bucket_id.id
  policy = data.aws_iam_policy_document.lb_logs_policy.json
}

data "aws_iam_policy_document" "lb_logs_policy" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [data.aws_elb_service_account.main.arn]
    }
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.memos_lb_logs_bucket_id.arn}/*"]
  }
}

data "aws_elb_service_account" "main" {}

# Route53 Hosted Zone

resource "aws_route53_zone" "memos_hosted_zone" {
  name = var.domain

  tags = local.tags
}

# ECR Repository

resource "aws_ecr_repository" "memos_repo" {
  name                 = "memos"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = local.tags
}

# OIDC

resource "aws_iam_openid_connect_provider" "memos_oidc_provider" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  tags = local.tags
}

resource "aws_iam_role" "memos_github_role" {
  name = "memos_github_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Federated = aws_iam_openid_connect_provider.memos_oidc_provider.arn
        }
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:ref:refs/heads/main"
          }
        }
      },
    ]
  })

  tags = local.tags
}

resource "aws_iam_policy" "memos_github_tight_policy" {
  name = "memos_github_tight_policy"
  policy = templatefile("${path.module}/github-tight-policy.json.tftpl", {
    region     = var.region
    account_id = var.account_id
  })
}

resource "aws_iam_role_policy_attachment" "memos_github_tight_policy_attach" {
  role       = aws_iam_role.memos_github_role.name
  policy_arn = aws_iam_policy.memos_github_tight_policy.arn
}