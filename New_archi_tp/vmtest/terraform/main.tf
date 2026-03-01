resource "proxmox_virtual_environment_vm" "testvm" {
  name      = "vm-test1-2526"
  node_name = "BO-3IL-02"
  vm_id     = 9001

  clone {
    vm_id = 100 # template cloud-init
  }

  cpu {
    cores = 2
  }

  memory {
    dedicated = 2048
  }
  agent {
    enabled = false
  }
  initialization {
    user_account {
      username = "devpro"
      password = "devpro0devpro0"
    }

    ip_config {
      ipv4 {
        #address = "10.10.10.11/24"
        address = "dhcp"
      }
    }
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }
  # NIC0 => infra
  network_device {
    bridge = "vmbr10"
  }

  # NIC1 => mgmt / autre réseau (si tu en as besoin)
  network_device {
    bridge = "vmbr0"
  }

}
