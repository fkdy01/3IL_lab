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
  insecure  = var.proxmox_insecure
}

# Zone SDN dédiée TP (ne touche pas DevPro/Cyber)
# IMPORTANT: zone_name et clés vnet <= 8 chars, sans dashes (contrainte Proxmox SDN / module).
module "sdn_tp" {
  source  = "hybridops-tech/sdn/proxmox"
  version = "~> 0.1.3"

  zone_name    = "tp${var.year}"     # ex: tp2526 (<=8 chars, OK)
  proxmox_node = var.proxmox_node
  proxmox_host = var.proxmox_host
  proxmox_url = var.proxmox_endpoint
  proxmox_token = var.proxmox_api_token

  # On veut DHCP dnsmasq sur les 3 réseaux
  enable_dhcp = true
  dns_domain  = var.dns_domain
  dns_lease   = var.dhcp_lease

  # Pour DHCP, le module exige enable_host_l3 = true
  enable_host_l3 = true

  # On ne veut PAS créer une "2ème sortie Internet" via SDN
  # => SNAT désactivé (Internet via vmbr0/ens18).
  enable_snat      = false
  uplink_interface = "vmbr0"

  # 3 réseaux : INFRA / DEV / PROD
  vnets = {
    infra = {
      vlan_id     = 252
      description = "TP ${var.year} - INFRA (GitLab/Registry/Runners/VM etudiants)"

      subnets = {
        infra = {
          cidr    = "10.31.2.0/24"
          gateway = "10.31.2.1"

          dhcp_enabled     = true
          dhcp_range_start = "10.31.2.10"
          dhcp_range_end   = "10.31.2.200"
          dhcp_dns_server  = var.dhcp_dns_server
        }
      }
    }

    dev = {
      vlan_id     = 253
      description = "TP ${var.year} - APP DEV (staging/hors-prod)"

      subnets = {
        dev = {
          cidr    = "10.31.20.0/24"
          gateway = "10.31.20.1"

          dhcp_enabled     = true
          dhcp_range_start = "10.31.20.10"
          dhcp_range_end   = "10.31.20.200"
          dhcp_dns_server  = var.dhcp_dns_server
        }
      }
    }

    prod = {
      vlan_id     = 254
      description = "TP ${var.year} - APP PROD (prod pedagogique)"

      subnets = {
        prod = {
          cidr    = "10.31.30.0/24"
          gateway = "10.31.30.1"

          dhcp_enabled     = true
          dhcp_range_start = "10.31.30.10"
          dhcp_range_end   = "10.31.30.200"
          dhcp_dns_server  = var.dhcp_dns_server
        }
      }
    }
  }
}