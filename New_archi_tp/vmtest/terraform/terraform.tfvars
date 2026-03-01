proxmox_endpoint     = "https://172.16.20.2:8006/"
proxmox_api_token    = "terraform_devops@pve!terraform_token=a307a6c4-9c0f-4a6f-9cfd-96dcf8333eab"
proxmox_tls_insecure = true

node_name = "BO-3IL-02"


# Optionnel : si tu veux changer les IPs/bridges
networks = {
  infra = { bridge = "vmbr10", ip_cidr = "10.10.10.10/24" }
  dev   = { bridge = "vmbr20", ip_cidr = "10.10.20.10/24" }
  prod  = { bridge = "vmbr30", ip_cidr = "10.10.30.10/24" }
}
