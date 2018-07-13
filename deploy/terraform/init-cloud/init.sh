#!/usr/bin/env bash
set -eux

# Input from cloud-init
GITHUB_REPO=$1
MAIL_USER=$2
MAIL_PASS=$3
DEPLOY_ID=$4
PROJECT_CODE=$5
ADMIN_MAIL=$6

# Mail setup
yes | apt-get install ssmtp
cat >/etc/ssmtp/ssmtp.conf <<EOL
mailhub=smtp.gmail.com:587

AuthUser=${MAIL_USER}
AuthPass=${MAIL_PASS}

UseTLS=Yes
UseSTARTTLS=YES

root=${MAIL_USER}
FromLineOverride=yes
rewriteDomain=gmail.com
AuthMethod=LOGIN
EOL

# GitHub setup
ssh-keyscan github.com 2> /dev/null >> /etc/ssh/ssh_known_hosts
git config --system advice.detachedHead false

# Setup work-dir
mkdir -p /etc/nixos
cd /etc/nixos
git rev-parse --is-inside-work-tree || git clone $GITHUB_REPO .

# Fire up NixOS infect
curl https://raw.githubusercontent.com/elitak/nixos-infect/master/nixos-infect | NIX_CHANNEL=nixos-18.03 bash 2>&1 | tee /var/log/nixos-infect.log

LOG_MAIL="To: Root\n"
LOG_MAIL+="From: DigitalOcean Logger\n"
LOG_MAIL+="Subject: Project '${PROJECT_CODE:-"-"}' log from '$(hostname)' #${DEPLOY_ID:-"-"}\n"
LOG_MAIL+="\n"
LOG_MAIL+="#### NixOS Infect log\n"
LOG_MAIL+="$(cat /var/log/nixos-infect.log)\n"
LOG_MAIL+="\n"
LOG_MAIL+="#### Full cloud init log\n"
LOG_MAIL+="$(/var/log/cloud-init.log)\n"
LOG_MAIL+="\n"

echo -n "$LOG_MAIL" | ssmtp -v krisjanis.veinbahs@gmail.com