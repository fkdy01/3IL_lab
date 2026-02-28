variable "proxmox_endpoint" {
  type        = string
  description = "https://<host>:8006/api2/json"
}

variable "proxmox_api_token" {
  type        = string
  description = "user@realm!tokenid=<secret>"
  sensitive   = true
}

variable "proxmox_insecure" {
  type    = bool
  default = true
}

variable "proxmox_node" {
  type    = string
  default = "BO-3IL-02"
}

variable "proxmox_host" {
  type        = string
  description = "IP/DNS du node, utilisé par le module pour SSH (host-side scripts DHCP)"
}

variable "year" {
  type    = string
  default = "2526"
}

variable "dns_domain" {
  type    = string
  default = "tp.local"
}

variable "dhcp_lease" {
  type    = string
  default = "24h"
}

# DNS annoncé par le DHCP interne (tu peux mettre ton DNS interne si tu en as un)
variable "dhcp_dns_server" {
  type    = string
  default = "1.1.1.1"
}