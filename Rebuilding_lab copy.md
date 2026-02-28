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
devpod up /home/devpro/vscode-remote-try-java --ide openvscode --debug
devpod stop vscode-remote-try-java
devpod delete vscode-remote-try-java




// For format details, see https://aka.ms/devcontainer.json. For config options, see the
// README at: https://github.com/devcontainers/templates/tree/main/src/java
{
	"name": "Java",
	// Or use a Dockerfile or Docker Compose file. More info: https://containers.dev/guide/dockerfile
	"image": "mcr.microsoft.com/devcontainers/java:1-21",

	"features": {
		"ghcr.io/devcontainers/features/java:1": {
			"version": "none",
			"installMaven": "true",
			"mavenVersion": "3.8.6",
			"installGradle": "false"
		}
	},

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
  // Point de montage : copie le projet local dans /workspace du container
  //"mounts": [
  //  "source=.,target=/workspace,type=copy"
  //],
  // Copie le projet dans /workspace à la création du container
  //"initializeCommand": "pwd && ls -al && mkdir -p /home/devpro/vscode-remote-try-java && ls -al",
  "initializeCommand": "echo 'initializeCommand' && pwd && ls -al",
  "onCreateCommand": "echo 'onCreateCommand' && git config --global http.sslverify 'false' && git clone https://devpro:bienvenue@172.16.21.16/devpro/vscode-remote-try-java.git",
  "postCreateCommand": "echo 'postCreateCommand ' && pwd && ls -al",
  // Force un "fake mount" vide → empêche le bind par défaut
  "workspaceMount": "source=volume-vscode-remote-try-java,target=/home/devpro/vscode-remote-try-java,type=volume",


  // Définit le dossier de travail dans le container
  "workspaceFolder": "/home/devpro/vscode-remote-try-java",
  //"initializeCommand": "cp -r /tmp/devpod/source/* /workspace/"
  //"initializeCommand": "pwd && ls -al && git clone https://dvp-srv-gitlab.campus12avenue.fr/devpro/vscode-remote-try-java.git /home/devpro/vscode-remote-try-java"

	// Use 'forwardPorts' to make a list of ports inside the container available locally.
	// "forwardPorts": [],

	// Use 'postCreateCommand' to run commands after the container is created.
	// "postCreateCommand": "java -version",

	// Uncomment to connect as root instead. More info: https://aka.ms/dev-containers-non-root.
	// "remoteUser": "root"
}


```

- creer un serveur gitlab
  - clonage du serveur docker
    - 172.16.21.16/
    - dvp-srv-gitlab
    - etc/hosts : dvp-srv-gitlab.campu12savenue.fr
  - installation de gitlab (https://docs.gitlab.com/install/docker/installation/)
    -snapshot
    ```
    sudo mkdir -p /srv/gitlab
    sudo chown -R devpro:devpro /srv/gitlab
    export GITLAB_HOME=/srv/gitlab
    ... mise à jour de l'etc/host

    ```
  - faire reconnaitre le certificat gitlab du serveur sur ubuntu
  ```
  Ajouter le certificat de ton GitLab dans la confiance système
  ```

C’est la bonne méthode (sûre, durable).

Récupère le certificat du serveur :

echo -n | openssl s_client -showcerts -connect dvp-srv-gitlab.campus12avenue.fr:443 | sed -ne '/-BEGIN CERTIFICATE-/,/-END CERTIFICATE-/p' > gitlab.crt

Ajoute-le à la liste des autorités de ton système :

Sur Ubuntu/Debian :

sudo cp gitlab.crt /usr/local/share/ca-certificates/
sudo update-ca-certificates

```

Pas de controle certificats sur git
git config --global http.sslverify "false"

```
