# Ce qu'il faut faire :

- Creer une vm ubuntu desktop dernier niveau pour les élèves

  - recupération ubuntu 24 desktop
  - installation avec 2 cartes reseau, sur devpro0 et vmbr0
  - Installer RDP : cela a été un peu compliqué
    - ne pas oublier d'installer dbus-x11
  - installer ssh client et server
  - creer la clef ssh devpro et la diffuser sur le serveur devcontainer
  - installer devpod
  - configurer devpod
    devpod provider add docker docker-remote --host ssh://devpro@172.16.20.190 --docker-path /usr/bin/docker --ssh-key-path ~/.ssh/id_rsa --remote-workspace-root /home/devpro/devpod-workspaces

- Creer un serveur docker dernier niveau pour container

  - recuperation dernier iso ubuntu server
  - il faut activer la 2eme carte reseau via /etc/netplan sur ubuntu server

  On est arriver à faire fonctionner avec devpod

```
devpod provider set-options docker -o DOCKER_HOST=ssh://devpro@172.16.20.190 --debug
devpod provider add docker

devpod up github.com/microsoft/vscode-remote-try-node --debug



  // For format details, see https://aka.ms/devcontainer.json. For config options, see the
// README at: https://github.com/devcontainers/templates/tree/main/src/javascript-node
{
        "name": "Node.js",
        // Or use a Dockerfile or Docker Compose file. More info: https://containers.dev/guide/dockerfile
        "image": "mcr.microsoft.com/devcontainers/javascript-node:1-18-bullseye",

        // Features to add to the dev container. More info: https://containers.dev/features.
        // "features": {},

        // Configure tool-specific properties.
        "customizations": {
                // Configure properties specific to VS Code.
                "vscode": {
                        "settings": {},
                        "extensions": [
                                "streetsidesoftware.code-spell-checker"
                        ]
                }
        },

        // Use 'forwardPorts' to make a list of ports inside the container available locally.
        // "forwardPorts": [3000],

        // Use 'portsAttributes' to set default properties for specific forwarded ports.
        // More info: https://containers.dev/implementors/json_reference/#port-attributes
        "portsAttributes": {
                "3000": {
                        "label": "Hello Remote World",
                        "onAutoForward": "notify"
                }
        },

        // Use 'postCreateCommand' to run commands after the container is created.
        "postCreateCommand": "yarn install",

        // Uncomment to connect as root instead. More info: https://aka.ms/dev-containers-non-root.
        // "remoteUser": "root"
//"workspaceMount": "source=${localWorkspaceFolder}/sub-folder,target=/home/devpro,type=bind"
"workspaceMount": "source=/home/devpro,target=/home,type=bind"
}

```
