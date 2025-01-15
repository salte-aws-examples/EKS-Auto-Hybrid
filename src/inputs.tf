variable commit {
  type        = string
  description = "Version of this code being deployed."
}

variable "remote_node_network" {
  type        = string
  description = "CIDR for on-premises nodes"
}

variable "remote_pod_network" {
  type        = string
  description = "CIDR for on-premises pods"
}

variable repository {
  type        = string
  description = "The version control repository where this code is stored."
}
