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

data "external" "get_session_token" {
  program = ["bash", "${path.module}/scripts/get_session_token.sh"]
}

data "template_file" "proxmox_user_data" {
  count = var.remote_node_count

  template = file("${path.module}/templates/user_data.tpl")
  vars     = {
    activation_code                 = aws_ssm_activation.default.activation_code
    activation_id                   = aws_ssm_activation.default.id
    aws_access_key_id               = data.external.get_session_token.result.access_key_id
    aws_secret_access_key           = data.external.get_session_token.result.secret_access_key
    aws_session_token               = data.external.get_session_token.result.session_token
    cilium_version                  = var.cilium_version
    cluster_name                    = aws_eks_cluster.default.name
    cluster_pool_ipv4_mask_size     = var.cilium_cluster_pool_ipv4_mask_size
    cluster_pool_ipv4_pod_cidr_list = cidrsubnet(var.remote_pod_network, var.cilium_cluster_pool_ipv4_mask_size - split("/", var.remote_pod_network)[1], count.index)
    domain                          = var.remote_node_domain
    hostname                        = format("${local.base_name}-%02d", count.index)
    id_rsa                          = indent(6, base64decode(var.remote_node_id_rsa))
    id_rsa_pub                      = indent(6, base64decode(var.remote_node_id_rsa_pub))
    k8s_service_host                = split("/", aws_eks_cluster.default.endpoint)[2]
    k8s_service_port                = "443"
    kubernetes_version              = var.kubernetes_version
    region                          = data.aws_region.default.name
  }
}

locals {
  account_number             = data.aws_caller_identity.current.id
  all_subnet_ids             = concat(data.aws_subnets.private.ids, data.aws_subnets.public.ids)
  base_name                  = "eks-auto-hybrid-${local.sanitized_workspace}"
  current_role_arn           = data.aws_caller_identity.current.arn
  eks_access_entries         = distinct(concat(local.eks_admin_arns, local.eks_cluster_admin_arns))
  eks_admin_arns             = ["arn:aws:iam::${local.account_number}:root", local.current_role_arn]
  eks_cluster_admin_arns     = ["arn:aws:iam::${local.account_number}:root", local.current_role_arn]
  proxmox_host               = "${var.proxmox_node}.${var.proxmox_domain}"
  # Replace any non-alphanumeric character (except hyphen and underscore) with a dash
  sanitized_workspace        = replace(lower(terraform.workspace), "/[^a-zA-Z0-9-_]/", "-")
  tags                       = {
    "salte/repository" = var.repository
    "salte/commit"     = var.commit
  }
  vpc_id                     = data.aws_vpc.main.id
}
