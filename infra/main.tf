module "vpc" {
  source = "./modules/vpc"

  tags   = local.tags
  region = var.region
}

module "acm" {
  source = "./modules/acm"

  tags               = local.tags
  memos_alb_dns_name = module.alb.memos_alb_dns_name
  memos_alb_zone_id  = module.alb.memos_alb_zone_id
  memos_domain       = var.domain
}

module "alb" {
  source = "./modules/alb"

  tags                 = local.tags
  memos_alb_sg         = module.vpc.memos_alb_sg
  memos_public_subnets = module.vpc.memos_public_subnets
  memos_vpc            = module.vpc.memos_vpc
  memos_cert_valid     = module.acm.memos_cert_valid
  memos_lb_logs        = data.terraform_remote_state.bootstrap_outputs.outputs.memos_lb_logs_bucket_id
}

module "ecs" {
  source = "./modules/ecs"

  tags                      = local.tags
  memos_repo_url            = data.terraform_remote_state.bootstrap_outputs.outputs.memos_repo_url
  memos_lb_target_group_arn = module.alb.memos_lb_target_group_arn
  memos_ecs_task_sg         = module.vpc.memos_ecs_task_sg
  memos_public_subnets      = module.vpc.memos_public_subnets
  region                    = var.region
  aws_account               = var.account_id
  ecr_repo                  = var.ecr_repo
}