terraform {
  required_version = ">= 1.6.0"

  required_providers {
    proxmox = {
      source = "bpg/proxmox"
      # "dernière version" -> on laisse ouvert en >=
      version = ">= 0.60.0"
    }
  }
}
