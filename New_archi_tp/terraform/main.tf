locals {
  # IMPORTANT:
  # L'ordre des ip_config doit correspondre à l'ordre des network_device
  # (limitation actuelle du provider bpg/proxmox). :contentReference[oaicite:1]{index=1}
  nics = [
    { name = "wan", bridge = "vmbr0", ip_cidr = "dhcp" },
    { name = "infra", bridge = var.networks.infra.bridge, ip_cidr = var.networks.infra.ip_cidr },
    { name = "dev", bridge = var.networks.dev.bridge, ip_cidr = var.networks.dev.ip_cidr },
    { name = "prod", bridge = var.networks.prod.bridge, ip_cidr = var.networks.prod.ip_cidr },
  ]
}

resource "proxmox_virtual_environment_file" "dnsmasq_user_data" {
  content_type = "snippets"
  datastore_id = var.snippets_datastore_id # ex: "local"
  node_name    = "BO-3IL-02"

  source_file {
    path = "${path.module}/cloud-init/dnsmasq-user-data.yaml"
  }
}

resource "proxmox_virtual_environment_vm" "dnsmasq" {
  name      = var.dnsmasq_vm.name
  node_name = var.node_name
  vm_id     = var.dnsmasq_vm.vm_id

  # Clone depuis un template cloud-init existant (VM template déjà prêt)
  clone {
    vm_id = var.dnsmasq_vm.template_vm
  }

  # Bonnes pratiques simples
  agent {
    enabled = true
  }

  operating_system {
    type = "l26"
  }

  cpu {
    cores = var.dnsmasq_vm.cores
  }

  memory {
    dedicated = var.dnsmasq_vm.memory_mb
  }

  # Disk: on force un disque "scsi0" sur le datastore cible (et resize si besoin)
  disk {
    datastore_id = var.dnsmasq_vm.datastore_id
    interface    = "scsi0"
    size         = var.dnsmasq_vm.disk_gb
    discard      = "on"
    iothread     = true
  }

  initialization {
    user_account {
      username = var.dnsmasq_vm.username
      password = var.dnsmasq_vm.password
    }

    # 3 IPs statiques (1 par NIC)
    dynamic "ip_config" {
      for_each = local.nics
      content {
        ipv4 {
          address = ip_config.value.ip_cidr
          # gateway = "x.x.x.x"   # inutile dans ton cas (bridges isolés)
        }
      }
    }
    user_data_file_id = proxmox_virtual_environment_file.dnsmasq_user_data.id
  }

  # 3 NICs branchées sur les bridges Linux vmbr10/20/30
  dynamic "network_device" {
    for_each = local.nics
    content {
      bridge = network_device.value.bridge
      model  = "virtio"
      # vlan_id = 0   # pas de VLAN ici
    }
  }
}
