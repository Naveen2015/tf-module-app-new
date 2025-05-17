locals {
  asg_tags = merge(var.tags, {Name = "${var.name}-${var.env}"})
  dns_name = "${var.dns_name}.${var.domain_name}"

  parameters = concat(var.parameters,[var.name])
  resources = [ for parameter in local.parameters : "arn:aws:ssm:us-east-1:${data.aws_caller_identity.identity.account_id}:parameter/${var.env}.${parameter}.*"]

}