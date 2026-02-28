#!/bin/bash
set -euo pipefail

# Doit être root
if [ "${EUID:-$(id -u)}" -ne 0 ]; then
  echo "Ce script doit être exécuté en root (ou via sudo)." >&2
  exit 1
fi

PASSWORD_CLEAR="bienvenue"

# Génère un hash SHA-512 pour /etc/shadow (bypass des règles PAM dictionnaire)
if ! command -v openssl >/dev/null 2>&1; then
  echo "Erreur: 'openssl' est requis (pour générer le hash du mot de passe)." >&2
  exit 1
fi
PASSWORD_HASH="$(openssl passwd -6 "$PASSWORD_CLEAR")"

# Détecte le groupe admin selon la distro (sudo Debian/Ubuntu, wheel RHEL-like)
SUDO_GROUP="sudo"
if ! getent group sudo >/dev/null 2>&1; then
  if getent group wheel >/dev/null 2>&1; then
    SUDO_GROUP="wheel"
  else
    echo "Erreur: aucun groupe 'sudo' ou 'wheel' n'a été trouvé." >&2
    exit 1
  fi
fi

for i in $(seq -w 1 10); do
  USER="s${i}"

  if id "$USER" &>/dev/null; then
    echo "Utilisateur $USER existe déjà."
    echo " → Mise à jour du mot de passe."
  else
    echo "Création de l'utilisateur $USER..."
    useradd -m -s /bin/bash "$USER"
    echo " → Utilisateur $USER créé."
  fi

  # Change le mot de passe même si l'utilisateur existe déjà
  usermod -p "$PASSWORD_HASH" "$USER"

  # Assure le sudoer (groupe sudo/wheel)
  if id -nG "$USER" | tr ' ' '\n' | grep -qx "$SUDO_GROUP"; then
    echo " → $USER est déjà dans le groupe $SUDO_GROUP. Rien à faire."
  else
    usermod -aG "$SUDO_GROUP" "$USER"
    usermod -aG docker "$USER"
    echo " → $USER ajouté au groupe $SUDO_GROUP."
  fi

  echo "--------------------------------------"
done

echo "Terminé."

