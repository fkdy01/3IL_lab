output "dnsmasq" {
  value = {
    vm_id   = proxmox_virtual_environment_vm.dnsmasq.vm_id
    name    = proxmox_virtual_environment_vm.dnsmasq.name
    node    = proxmox_virtual_environment_vm.dnsmasq.node_name
    bridges = [for n in local.nics : n.bridge]
    ips     = {
      infra = var.networks.infra.ip_cidr
      dev   = var.networks.dev.ip_cidr
      prod  = var.networks.prod.ip_cidr
    }
  }
}