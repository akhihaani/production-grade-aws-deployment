variable "region" {
  type        = string
  description = "AWS region to deploy into"
  # no default → Terraform will demand a value 
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
  # no default → Terraform will demand a value
}

variable "domain" {
  type        = string
  description = "Domain"
  # no default → Terraform will demand a value
}

variable "github_repo" {
  type        = string
  description = "GitHub Repository"
}

variable "ecr_repo" {
  type        = string
  description = "ECR Repository URL"
}