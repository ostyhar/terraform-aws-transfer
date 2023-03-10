data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

resource "aws_transfer_server" "main" {
  identity_provider_type = "SERVICE_MANAGED"
  logging_role           = aws_iam_role.logs_role.arn

  endpoint_type = var.endpoint_type
  dynamic "endpoint_details" {
    for_each = var.endpoint_details

    content {
      address_allocation_ids = endpoint_details.value["address_allocation_ids"]
      subnet_ids             = endpoint_details.value["subnet_ids"]
      vpc_id                 = endpoint_details.value["vpc_id"]
      security_group_ids     = endpoint_details.value["security_group_ids"]
    }
  }

  protocols            = var.protocols
  domain               = var.domain
  host_key             = var.host_key
  security_policy_name = var.security_policy_name
  certificate          = var.certificate

  tags = merge({
    Name       = var.name
    Automation = "Terraform"
  }, var.tags)
}

resource "aws_route53_record" "main" {
  count   = length(var.domain_name) > 0 && length(var.zone_id) > 0 ? 1 : 0
  name    = var.domain_name
  zone_id = var.zone_id
  type    = "CNAME"
  ttl     = "300"
  records = [
    aws_transfer_server.main.endpoint
  ]
}

data "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
}
