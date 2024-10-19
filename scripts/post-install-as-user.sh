#!/bin/bash
# [CUSTOM] Post-installation scripts
# Run this a 'vagrant'
set -e

# Redirect both stdout and stderr to a log file and to the console
exec > >(tee -a /var/tmp/config_as_user.log) 2>&1

# Should user provide his credentials again ?
NO_INIT_CREDENTIALS=false

# Should we clone again ?
NO_CLONE=false

#[CUSTOM]
MY_PROJECT="MyProject"

# Alias definition ('shopt' allows to use alias in the shell)
# [CUSTOM] Add here your custom aliases
shopt -s expand_aliases

# Parsing des arguments
usage() {
    echo "Usage: $0 [--no-init-credentials] [--no-clone]"
    exit 1
}

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --no-init-credentials)
            NO_INIT_CREDENTIALS=true
            ;;
        --no-clone)
            NO_CLONE=true
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
    shift
done

# Check that we are 'vagrant'
if [[ $USER != "vagrant" ]]; then
   echo "[ERROR] This script must be executed with 'vagrant' user" 
   exit 1
fi

# Clone Git repositories 
WORKSPACES="$HOME/workspaces"
# [CUSTOM] Set here the projects group URL 
URL_GIT="https://github/acme/foo"

# All repositories
DEPOTS_PROJET=(
https://$URL_GIT/module_a.git \
https://$URL_GIT/module_b.git

# Backup potential previous workspaces
if [[ "$NO_CLONE" == false ]]; then
  cd $HOME
  if [[ -d $WORKSPACES ]]; then
    echo "[INFO] Existing workspace, saved"
    mv $WORKSPACES $WORKSPACES-$(date +%Y%m%d-%H%M)
  fi
  mkdir -p $WORKSPACES/$MY_PROJECT 2>/dev/null || true
fi

# Git configuration
if [[ "$NO_INIT_CREDENTIALS" == false ]]; then
  read -p "Full Name: " git_name
  read -p "E-mail: " git_email
  git config --global user.name "$git_name"
  git config --global user.email "$git_email"
  # [CUSTOM] Use vim as default editor (yes, I hate nano)
  git config --global core.editor "vim"
  # [CUSTOM] Set preferred pull method to rebase
  git config --global pull.rebase true

  # Store Git credentials
  read -p "Git login: " git_username
      read -sp "Access token: " git_password
      echo
      git credential-store --file ~/.git-credentials store <<EOF
protocol=https
host=github.com
username=$git_username
password=$git_password
EOF
  git config --global credential.helper store
  echo "[INFO] Git credentials saved."
fi

# Create default shortcuts
dconf write /org/gnome/shell/favorite-apps "['dbeaver-ce.desktop', 'org.gnome.Terminal.desktop', 'idea.desktop', 'bruno.desktop', 'firefox-esr.desktop','code.desktop','org.gnome.Nautilus.desktop','geany.desktop','thunar.desktop']"

# End
echo "[INFO] Workspace configured, welcome onboard 😀 !"

