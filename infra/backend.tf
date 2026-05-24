# tfstate locking
terraform {
  required_version = ">= 1.1.9"
  backend "s3" {
    bucket         = "memos-tfstate-310829530244"
    key            = "infra/terraform.tfstate"
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-locks"
    encrypt        = true
  }
}

# Allows being able to take outputs from bootstrap as variables in infra
data "terraform_remote_state" "bootstrap_outputs" {
  backend = "local"
  config = {
    path = "../bootstrap/terraform.tfstate"
  }
}

# Format: data.terraform_remote_state.bootstrap_outputs.<var_name>