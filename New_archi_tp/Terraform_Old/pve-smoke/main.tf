terraform {
  required_version = ">= 1.5.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.50.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = true
}

# Test très simple : lire un objet non destructif
data "proxmox_virtual_environment_user" "me" {
  user_id = var.proxmox_user_id
}

output "user_found" {
  value = data.proxmox_virtual_environment_user.me.user_id
}

variable "proxmox_endpoint" {
  description = "URL de l'API Proxmox VE (ex: https://host:port/)"
  type        = string
  default     = "https://172.16.20.2:8006/"
}


variable "proxmox_api_token" { 
    type = string
    sensitive = true
}

variable "proxmox_user_id" { type = string }