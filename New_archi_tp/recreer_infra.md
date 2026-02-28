## Synthèse de la recommandation finale (sans toucher à l’existant)

**Objectif :** déployer une architecture “entreprise” **rejouable par année**, **sans modifier** tes zones SDN existantes (`DevPro`, `Cyber`), et avec **3 réseaux internes** (INFRA / APP-DEV / APP-PROD) gérés en **Infra as Code via Terraform**.

**Principe :**

- On crée **une nouvelle zone SDN dédiée** à l’année (ex: `tp2526`) + **3 VNets** (ex: `infra`, `dev`, `prod`).
- Chaque VNet a son **subnet /24** et un **DHCP dnsmasq**.
- Pour éviter les soucis de “double default route” que tu as déjà vus, on garde **Internet via `vmbr0`** (ens18), et on **empêche** les réseaux internes (ens19/ens20/ens21) de devenir la route par défaut côté VM (cf. check “never-default” plus bas).
- **Rollback** : `terraform destroy` supprime uniquement cette nouvelle zone/vnets/subnets.

> Le module Terraform que je te propose (hybridops-tech/sdn/proxmox) est conçu pour Proxmox VE 8.x, SDN, avec DHCP dnsmasq et options L3/SNAT (qu’on désactive si on veut) et il impose des IDs SDN courts (≤ 8 chars, sans tirets). ([GitHub][1])

---

## Chapitre — Valider que Terraform “fonctionne” bien avec Proxmox (avant de créer du SDN)

### A. Prérequis Proxmox

1. **Créer un API Token**

- Proxmox GUI → _Datacenter → Permissions → API Tokens_ (création token pour un user dédié “terraform”).
  Le provider bpg/proxmox supporte l’auth via **endpoint + api_token**. ([registry.terraform.io][2])

2. **Permissions minimales**

- Pour gérer SDN : il faudra des droits cluster/networking (souvent via rôle _Administrator_ en lab, ou un rôle dédié si tu veux faire “entreprise”).

3. **SDN activé**

- Les conf SDN sont stockées dans `/etc/pve/sdn` (cluster-wide). ([pve.proxmox.com][3])

### B. Prérequis machine Terraform (poste ou runner)

- Terraform ≥ 1.5
- Accès HTTPS à `https://BO-3IL-02:8006/api2/json`
- (Optionnel mais recommandé) variables d’environnement pour secrets

### C. Test “safe” de connectivité Terraform (sans modifier Proxmox)

Crée un dossier `pve-smoke/` avec :

```hcl
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
  insecure  = true
}

# Test très simple : lire un objet non destructif
data "proxmox_virtual_environment_user" "me" {
  user_id = var.proxmox_user_id
}

output "user_found" {
  value = data.proxmox_virtual_environment_user.me.user_id
}

variable "proxmox_endpoint" { type = string }
variable "proxmox_api_token" { type = string; sensitive = true }
variable "proxmox_user_id" { type = string }
```

Puis :

```bash
terraform init
terraform plan
```

Si ça passe : **Terraform + API Proxmox OK**.

> Exemple de config provider bpg/proxmox (endpoint/api_token/insecure) : ([Stéphane ROBERT - DevSecOps][4])

---

## Terraform complet — Zone TP 2526 + 3 réseaux + DHCP dnsmasq (sans altérer DevPro/Cyber)

### Choix technique

On utilise le module **`hybridops-tech/sdn/proxmox`** :

- Gère zone + vnets + subnets
- DHCP dnsmasq piloté par Terraform
- Contraintes SDN : IDs courts ≤ 8, sans tiret (important !) ([GitHub][1])

### Naming (compatible contraintes SDN)

- `zone_name` : `tp2526`
- VNets : `infra`, `dev`, `prod` (≤ 8 chars)
- VLAN IDs (sur `vmbr0`) : `252`, `253`, `254` _(valeurs d’exemple, faciles à repérer)_

> Le module est “VLAN-backed” : il crée une zone SDN attachée à un bridge VLAN-aware (typiquement `vmbr0`). ([GitHub][1])

---

# 📁 Arborescence

```
pve-tp-devops-sdn/
  main.tf
  variables.tf
  outputs.tf
  terraform.tfvars.example
```

---

### `variables.tf`

```hcl
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
```

---

### `main.tf`

```hcl
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
```

> Pourquoi `gateway` alors que tu voulais “intranet pur” ?
> Parce que ce module impose `enable_host_l3 = true` pour DHCP dnsmasq (il doit attacher dnsmasq à une interface L3). ([GitHub][1])
> **Mais** on évite que ça casse tes VMs en appliquant côté VM le réglage “ne jamais utiliser cette interface comme route par défaut” (ci-dessous).

---

### `outputs.tf`

```hcl
output "zone_name" {
  value = module.sdn_tp.zone_name
}

output "vnets" {
  value = module.sdn_tp.vnets
}

output "subnets" {
  value = module.sdn_tp.subnets
}
```

---

### `terraform.tfvars.example`

```hcl
proxmox_endpoint  = "https://BO-3IL-02:8006/api2/json"
proxmox_api_token = "root@pam!terraform=<SECRET>"
proxmox_insecure  = true

proxmox_node = "BO-3IL-02"
proxmox_host = "172.16.20.2"   # IP de BO-3IL-02 (à adapter)

year = "2526"

dns_domain       = "tp.local"
dhcp_lease       = "24h"
dhcp_dns_server  = "1.1.1.1"
```

---

## Étape “réseau VM” indispensable (anti double default-route)

Quand tu ajoutes une NIC sur `infra/dev/prod`, tu dois empêcher NetworkManager d’en faire la route par défaut.

Sur la VM (ex: interface `ens19`) :

```bash
# identifier le nom de connexion NM (ex: "netplan-ens19" ou autre)
nmcli -f NAME,DEVICE connection show

# activer "never-default" (IPv4)
nmcli connection modify "netplan-ens19" ipv4.never-default yes

# idem en IPv6 si besoin
nmcli connection modify "netplan-ens19" ipv6.never-default yes

nmcli connection down "netplan-ens19" && nmcli connection up "netplan-ens19"
```

**Contrôle attendu :**

```bash
ip route | grep ^default
```

➡️ **une seule** default route (celle de `ens18` via `172.16.23.254`).

---

## Apply / rollback (pratique)

```bash
terraform init
terraform plan
terraform apply
```

Rollback immédiat :

```bash
terraform destroy
```

Si Proxmox SDN n’applique pas automatiquement dans ta version, l’équivalent CLI de “Apply SDN” est :

```bash
pvesh set /cluster/sdn
```

([Proxmox Support Forum][5])

---

Si tu veux, je peux aussi te donner **le petit module Terraform “VM clone GitLab”** (avec tags Proxmox + double NIC) pour que tu puisses cloner ta VM GitLab et la brancher sur `infra` en 2 minutes, dans le même repo IaC.

[1]: https://github.com/hybridops-studio/terraform-proxmox-sdn "GitHub - hybridops-tech/terraform-proxmox-sdn: Terraform module for Proxmox SDN with automated DHCP via dnsmasq"
[2]: https://registry.terraform.io/providers/bpg/proxmox/latest/docs?utm_source=chatgpt.com "Docs overview | bpg/proxmox - Terraform Registry"
[3]: https://pve.proxmox.com/pve-docs/chapter-pvesdn.html?utm_source=chatgpt.com "Software-Defined Network"
[4]: https://blog.stephane-robert.info/docs/virtualiser/type1/proxmox/terraform/?utm_source=chatgpt.com "Provisionner des VM avec Terraform"
[5]: https://forum.proxmox.com/threads/how-to-apply-sdn-changes-from-the-cli.87762/?utm_source=chatgpt.com "How to apply SDN changes from the CLI?"
