variable "app_name" {
  type        = string
  description = "The name of this app."
}

variable "account_id" {
  type        = number
  description = "The AWS account number of the baseline account."
}

variable "region" {
  type        = string
  description = "Stack name - will be used as prefix on resources"
  default     = "us-east-1"
}

variable "frequency" {
  type        = string
  description = "A CloudWatch schedule expression for when to rotate the credentials & drone secrets."
  default     = "rate(30 days)"
}

variable "tags" {
  type        = map(any)
  default     = {}
  description = "Tags to propagate to resources created by this module"
}

variable "route53_hosted_zone" {
  type        = string
  description = "The Hosted zone ID of the AWSMA account's Route53 zone."
}

variable "environment" {
  type        = string
  description = "current environment"
}

variable "common_tags" {
  type        = map(any)
  description = "The map of tags that will be attached to all resources for this Terraform configuration."
}
