proxmox_endpoint      = "https://172.16.20.2:8006/"
proxmox_api_token     = "terraform_devops@pve!terraform_token=a307a6c4-9c0f-4a6f-9cfd-96dcf8333eab"
proxmox_tls_insecure  = true

node_name = "BO-3IL-02"

dnsmasq_vm = {
  name         = "vm-dnsmasq-2526"
  vm_id        = 9000
  template_vm  = 100          # <-- VMID du template cloud-init
  datastore_id = "local-15TB"  # <-- adapte (local, local-lvm, etc.)
  cores        = 2
  memory_mb    = 2048
  disk_gb      = 16
  username     = "devpro"
  password     = "devpro0devpro0"
}

# Optionnel : si tu veux changer les IPs/bridges
networks = {
  infra = { bridge = "vmbr10", ip_cidr = "10.10.10.10/24" }
  dev   = { bridge = "vmbr20", ip_cidr = "10.10.20.10/24" }
  prod  = { bridge = "vmbr30", ip_cidr = "10.10.30.10/24" }
}