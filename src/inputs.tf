variable cilium_cluster_pool_ipv4_mask_size {
  type        = string
  description = "The size of the mask for the cluster pool IPv4 address space."
}

variable cilium_version {
  type        = string
  default     = "1.16"
  description = "Version of Cilium to deploy."
}

variable commit {
  type        = string
  description = "Version of this code being deployed."
}

variable kubernetes_version {
  type        = string
  default     = "1.31"
  description = "Version of Kubernetes to deploy."
}

variable proxmox_cloud_init_storage {
  type        = string
  description = "The storage location on the Proxmox cluster node where cloud-init data should be stored."
}

variable proxmox_domain {
  type        = string
  description = "The domain of the Proxmox cluster node."
}

variable proxmox_node {
  type        = string
  description = "The host name of the Proxmox cluster node."
}

variable proxmox_password {
  type        = string
  description = "The password used to connect to the Proxmox cluster node."
}

variable proxmox_port {
  type        = number
  description = "The web application/api port on the Proxmox cluster node."
}

variable proxmox_ubuntu_template {
  type        = string
  description = "The name of the Proxmox template to use for creating hybrid nodes."
}

variable proxmox_user {
  type        = string
  description = "The user name used to connect to the Proxmox cluster node."
}

variable proxmox_user_data_file_path {
  type        = string
  description = "Location on the Proxmox cluster node where user data scripts should be placed for use in Proxmox VM provisioning."
}

variable proxmox_user_data_file_url {
  type        = string
  description = "Location on the Proxmox cluster node where user data scripts should be referenced for use in Proxmox VM provisioning."
}

variable proxmox_vm_storage {
  type        = string
  description = "The storage location on the Proxmox cluster node where VMs should be created."
}

variable remote_node_core_count {
  type        = number
  description = "Number of virtual CPU cores to assign to on-premises nodes."
}

variable remote_node_count {
  type        = number
  description = "Number of on-premises nodes to create."
}

variable remote_node_disk_size {
  type        = string
  description = "Size of the disk to assign to on-premises nodes."
}

variable remote_node_domain {
  type        = string
  description = "The domain to be assigned to on-premises nodes."
}

variable remote_node_id_rsa {
  type        = string
  description = "The private key to be assigned to on-premises nodes."
}

variable remote_node_id_rsa_pub {
  type        = string
  description = "The public key to be assigned to on-premises nodes."
}

variable remote_node_memory_size {
  type        = number
  description = "Size of the memory to assign to on-premises nodes."
}

variable remote_node_network {
  type        = string
  description = "CIDR for on-premises nodes"
}

variable remote_node_network_adapter_bridge {
  type        = string
  description = "The bridge adapter to use for on-premises nodes."
}

variable remote_node_network_adapter_id {
  type        = string
  description = "The network adapter ID to use for on-premises nodes."
}

variable remote_node_network_adapter_model {
  type        = string
  description = "The network adapter model to use for on-premises nodes."
}

variable remote_node_network_gateway {
  type        = string
  description = "The gateway to use for on-premises nodes."
}

variable remote_node_scsi_controller {
  type        = string
  description = "The SCSI controller to use for on-premises nodes."
}

variable remote_node_socket_count {
  type        = number
  description = "Number of virtual CPU sockets to assign to on-premises nodes."
}

variable remote_pod_network {
  type        = string
  description = "CIDR for on-premises pods"
}

variable repository {
  type        = string
  description = "The version control repository where this code is stored."
}
