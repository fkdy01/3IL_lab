variable "snippets_datastore_id" {
  description = "Datastore pour stocker les snippets cloud-init (ex: local)"
  type        = string
  default     = "local"
}

variable "proxmox_ssh_username" {
  description = "Utilisateur Linux sur le node Proxmox (pour déposer les snippets)"
  type        = string
}

variable "proxmox_ssh_password" {
  description = "Mot de passe de l'utilisateur Linux (SSH) sur le node Proxmox"
  type        = string
  sensitive   = true
}

variable "proxmox_endpoint" {
  description = "Ex: https://pve.example:8006/"
  type        = string
}

variable "proxmox_api_token" {
  description = "Ex: terraform@pve!token=xxxx"
  type        = string
  sensitive   = true
}

variable "proxmox_tls_insecure" {
  description = "true si CA interne non déployée sur la machine Terraform"
  type        = bool
  default     = true
}

variable "node_name" {
  description = "Nom du node Proxmox"
  type        = string
  default     = "BO-3IL-02"
}

variable "dnsmasq_vm" {
  description = "Paramètres de la VM dnsmasq"
  type = object({
    name         = string
    vm_id        = number
    template_vm  = number # VMID du template cloud-init existant
    datastore_id = string # ex: local-lvm
    cores        = number
    memory_mb    = number
    disk_gb      = number
    username     = string
    password     = string
  })
}

variable "networks" {
  description = "3 réseaux via bridges Linux déjà créés"
  type = object({
    infra = object({ bridge = string, ip_cidr = string })
    dev   = object({ bridge = string, ip_cidr = string })
    prod  = object({ bridge = string, ip_cidr = string })
  })

  default = {
    infra = { bridge = "vmbr10", ip_cidr = "10.10.10.10/24" }
    dev   = { bridge = "vmbr20", ip_cidr = "10.10.20.10/24" }
    prod  = { bridge = "vmbr30", ip_cidr = "10.10.30.10/24" }
  }
}

