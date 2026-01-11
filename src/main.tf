# *****************************************************************************
# Provision Kubernetes-Specific Subnet Tags
# *****************************************************************************
resource "aws_ec2_tag" "all" {
  for_each = toset(local.all_subnet_ids)

  key         = "kubernetes.io/cluster/${local.base_name}-cluster"
  resource_id = each.value
  value       = "shared"
}

resource "aws_ec2_tag" "private" {
  for_each = toset(data.aws_subnets.private.ids)

  key         = "kubernetes.io/role/internal-elb"
  resource_id = each.value
  value       = "1"
}

resource "aws_ec2_tag" "public" {
  for_each = toset(data.aws_subnets.public.ids)

  key         = "kubernetes.io/role/elb"
  resource_id = each.value
  value       = "1"
}

# *****************************************************************************
# Provision IAM Role for EKS Cluster
# *****************************************************************************
resource "aws_iam_role" "eks_cluster_role" {
  name = "${local.sanitized_workspace}-cluster-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_block_storage_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSBlockStoragePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_compute_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSComputePolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_load_balancing_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSLoadBalancingPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

resource "aws_iam_role_policy_attachment" "eks_networking_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSNetworkingPolicy"
  role       = aws_iam_role.eks_cluster_role.name
}

# *****************************************************************************
# Provision IAM Role for EKS Nodes
# *****************************************************************************
resource "aws_iam_role" "eks_node_role" {
  name = "${local.sanitized_workspace}-eks-node-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.eks_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_node_minimal_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.eks_node_role.name
}

# *****************************************************************************
# Provision IAM Role for EKS Hybrid Nodes
# *****************************************************************************
resource "aws_iam_role" "eks_hybrid_node_role" {
  name = "${local.sanitized_workspace}-eks-hybrid-node-role"
  tags = local.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole"
        ]
        Effect = "Allow"
        Principal = {
          Service = "ssm.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_hybrid_node_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
  role       = aws_iam_role.eks_hybrid_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_hybrid_node_minimal_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodeMinimalPolicy"
  role       = aws_iam_role.eks_hybrid_node_role.name
}

resource "aws_iam_role_policy_attachment" "eks_hybrid_node_ssm_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.eks_hybrid_node_role.name
}

resource "aws_iam_policy" "eks_hybrid_node_policy" {
  name = "${local.sanitized_workspace}-eks-hybrid-node-policy"
  path = "/"
  description = "Policy to allow EKS Hybrid Nodes to register with the cluster"

  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "eks:DescribeCluster",
                "ssm:DeregisterManagedInstance",
                "ssm:DescribeInstanceInformation",
                "iam:CreatePolicy",
                "iam:CreateRole",
                "iam:AttachRolePolicy"
            ],
            "Resource": "*"
        }
    ]
})
}

resource "aws_iam_role_policy_attachment" "eks_hybrid_node_policy" {
  policy_arn = aws_iam_policy.eks_hybrid_node_policy.arn
  role       = aws_iam_role.eks_hybrid_node_role.name
}

# *****************************************************************************
# Provision Security Group to Enable Cluster Communication from Hybrid Nodes
# *****************************************************************************
resource "aws_security_group" "eks_hybrid_node_sg" {
  name        = "${local.sanitized_workspace}-eks-hybrid-node-sg"
  description = "Allow traffic from EKS Hybrid Nodes"
  vpc_id      = local.vpc_id
  tags        = local.tags
}

resource "aws_security_group_rule" "eks_hybrid_node_sg_rule_ingress" {
  type              = "ingress"
  description       = "Allow traffic from EKS Hybrid Nodes"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = [var.remote_node_network]
  security_group_id = aws_security_group.eks_hybrid_node_sg.id
}

resource "aws_security_group_rule" "eks_hybrid_node_sg_rule_egress" {
  type              = "egress"
  description       = "Allow all egress traffic"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.eks_hybrid_node_sg.id
}

# *****************************************************************************
# Provision EKS Cluster
# *****************************************************************************
resource "aws_eks_cluster" "default" {
  name     = "${local.base_name}-cluster"
  role_arn = aws_iam_role.eks_cluster_role.arn
  tags     = local.tags
  version  = var.kubernetes_version

  access_config {
    authentication_mode = "API_AND_CONFIG_MAP"
  }

  bootstrap_self_managed_addons = false

  compute_config {
    enabled       = true
    node_pools    = ["general-purpose", "system"]
    node_role_arn = aws_iam_role.eks_node_role.arn
  }

  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  kubernetes_network_config {
    elastic_load_balancing {
      enabled = true
    }
  }

  storage_config {
    block_storage {
      enabled = true
    }
  }

  remote_network_config {
    remote_node_networks {
      cidrs = [var.remote_node_network]
    }
    remote_pod_networks {
      cidrs = [var.remote_pod_network]
    }
  }

  vpc_config {
    security_group_ids      = [aws_security_group.eks_hybrid_node_sg.id]
    subnet_ids              = data.aws_subnets.private.ids
    endpoint_private_access = true
    endpoint_public_access  = false
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# *****************************************************************************
# Provision EKS Cluster Access
# *****************************************************************************
resource "aws_eks_access_entry" "hybrid_node" {
  cluster_name      = aws_eks_cluster.default.name
  principal_arn     = aws_iam_role.eks_hybrid_node_role.arn
  type              = "HYBRID_LINUX"
}

resource "aws_eks_access_entry" "default" {
  count = length(local.eks_access_entries)

  cluster_name      = aws_eks_cluster.default.name
  principal_arn     = local.eks_access_entries[count.index]
  type              = "STANDARD"
}

resource "aws_eks_access_policy_association" "eks_admin" {
  count = length(local.eks_admin_arns)

  cluster_name  = aws_eks_cluster.default.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  principal_arn = local.eks_admin_arns[count.index]

  access_scope {
    type       = "cluster"
  }
}

resource "aws_eks_access_policy_association" "eks_cluster_admin" {
  count = length(local.eks_cluster_admin_arns)

  cluster_name  = aws_eks_cluster.default.name
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  principal_arn = local.eks_cluster_admin_arns[count.index]

  access_scope {
    type       = "cluster"
  }
}

# *****************************************************************************
# Provision Hybrid Node
# *****************************************************************************
resource "aws_ssm_activation" "default" {
  name               = local.base_name
  description        = "Activation for hybrid nodes associated with EKS cluster \"${aws_eks_cluster.default.name}.\""
  iam_role           = aws_iam_role.eks_hybrid_node_role.id
  registration_limit = var.remote_node_count
  tags               = local.tags
  depends_on         = [
    aws_iam_role.eks_hybrid_node_role,
    aws_iam_role_policy_attachment.eks_hybrid_node_registry_policy,
    aws_iam_role_policy_attachment.eks_hybrid_node_minimal_policy,
    aws_iam_role_policy_attachment.eks_hybrid_node_ssm_policy,
    aws_iam_policy.eks_hybrid_node_policy,
    aws_iam_role_policy_attachment.eks_hybrid_node_policy
  ]
}

resource "null_resource" "user_data" {
  count = var.remote_node_count

  connection {
    type     = "ssh"
    user     = var.proxmox_user
    password = var.proxmox_password
    host     = local.proxmox_host
  }

  triggers = {
    file = sha256(data.template_file.proxmox_user_data[count.index].rendered)
  }

  provisioner "file" {
    content  = data.template_file.proxmox_user_data[count.index].rendered
    destination = "${var.proxmox_user_data_file_path}/${sha256(data.template_file.proxmox_user_data[count.index].rendered)}"
  }
}

resource "proxmox_vm_qemu" "default" {
  count = var.remote_node_count

  cicustom                = "user=${var.proxmox_user_data_file_url}/${sha256(data.template_file.proxmox_user_data[count.index].rendered)}"
  clone                   = var.proxmox_ubuntu_template
  cores                   = var.remote_node_core_count
  desc                    = "Hybrid node associated with EKS cluster \"${aws_eks_cluster.default.name}\" hosted in AWS account number \"${local.account_number}.\""
  full_clone              = true
  # ipconfig0               = "ip=${var.IP_ADDRESS}/${var.NETMASK},gw=${var.remote_node_network_gateway}"
  memory                  = var.remote_node_memory_size
  name                    = format("${local.base_name}-%02d", count.index)
  os_type                 = "cloud-init"
  scsihw                  = var.remote_node_scsi_controller
  sockets                 = var.remote_node_socket_count
  target_node             = var.proxmox_node

  disks {
    ide {
      ide0 {
        cloudinit {
          storage = var.proxmox_cloud_init_storage
        }
      }
    }

    scsi {
      scsi0 {
        disk {
          size    = var.remote_node_disk_size
          storage = var.proxmox_vm_storage
        }
      }
    }
  }

  network {
    id     = var.remote_node_network_adapter_id
    model  = var.remote_node_network_adapter_model
    bridge = var.remote_node_network_adapter_bridge
   }

  depends_on  = [
    null_resource.user_data,
  ]
}
