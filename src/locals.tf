data "aws_caller_identity" "current" {}

# EKS does not support creating control plane instances in us-east-1e
data "aws_subnets" "private" {
  filter {
    name   = "tag:salte/type"
    values = ["private"]
  }
  filter {
    name   = "tag:salte/available"
    values = [true]
  }
}

data "aws_subnet" "private" {
  for_each = toset(data.aws_subnets.private.ids)
  id       = each.value
}

data "aws_subnets" "public" {
  tags = {
    "salte/type" = "public"
  }
}

data "aws_vpc" main {}

locals {
  account_number         = data.aws_caller_identity.current.id
  all_subnet_ids         = concat(data.aws_subnets.private.ids, data.aws_subnets.public.ids)
  current_role_arn       = data.aws_caller_identity.current.arn
  eks_access_entries     = distinct(concat(local.eks_admin_arns, local.eks_cluster_admin_arns))
  eks_admin_arns         = ["arn:aws:iam::${local.account_number}:root", local.current_role_arn]
  eks_cluster_admin_arns = ["arn:aws:iam::${local.account_number}:root", local.current_role_arn]
  eks_cluster_name         = "${local.sanitized_workspace}-cluster"
  kubernetes_version   = "1.31"
  # Replace any non-alphanumeric character (except hyphen and underscore) with a dash
  sanitized_workspace  = replace(lower(terraform.workspace), "/[^a-zA-Z0-9-_]/", "-")
  tags                 = {
    "salte/repository" = var.repository
    "salte/commit"     = var.commit
  }
  vpc_id               = data.aws_vpc.main.id
}
