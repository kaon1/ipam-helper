module "ipam-helper" {
  source              = "../modules/ipam-helper"
  environment         = "prd"
  app_name            = var.app_name
  account_id          = var.account_id
  route53_hosted_zone = var.route53_hosted_zone
  image_tag           = "latest"
  common_tags         = local.common_tags
}
