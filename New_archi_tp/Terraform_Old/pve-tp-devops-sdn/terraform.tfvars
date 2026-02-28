proxmox_endpoint  = "https://172.16.20.2:8006/api2/json"
proxmox_api_token = "terraform_devops@pve!terraform_token=a307a6c4-9c0f-4a6f-9cfd-96dcf8333eab"
proxmox_insecure  = true

proxmox_node = "BO-3IL-02"
proxmox_host = "172.16.20.2"   # IP de BO-3IL-02 (à adapter)

year = "2526"

dns_domain       = "tp.local"
dhcp_lease       = "24h"
dhcp_dns_server  = "1.1.1.1"