terraform {
  required_version = ">= 1.10.3"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.84.0"
    }
    external = {
      source = "hashicorp/external"
      version = "2.3.4"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
    null = {
      source = "hashicorp/null"
      version = "3.2.3"
    }
    proxmox = {
      source = "Telmate/proxmox"
      version = "3.0.1-rc6"
    }
  }
  backend "s3" {}
}

provider "aws" {}

provider "proxmox" {
  pm_api_url = "https://${var.proxmox_node}.${var.proxmox_domain}:${var.proxmox_port}/api2/json"
  pm_password = var.proxmox_password
  pm_tls_insecure = true
  pm_user = "${var.proxmox_user}@pam"
}
