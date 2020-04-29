#!/bin/bash

# ========================================================
# Generate encrypted config file for ansible based on a given template
# 1st arg [$1] - template of the YAML file that contains the secret to be encrypted
# 2nd arg [$2] - location of the encrypted YAML file
# ========================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VAULT_PASSWORD_FILE=$DIR/.vault.pwd

PWD_FILE_TEMPLATE=$1
PWD_FILE=$2

echo "============================"
echo "Credential File Generator"
echo "============================"
echo "encrypted file location: $PWD_FILE"

if [ ! -f $VAULT_PASSWORD_FILE ]; then
  echo "Vault secret file does not exists. It will be created."
  echo "Please provide a secret or password for the vault: "
  read -s SECRET;
  echo $SECRET > $VAULT_PASSWORD_FILE
else
  echo "Vault secret file exists. It will be used."
fi

yes | cp -f $PWD_FILE_TEMPLATE $PWD_FILE
ansible-vault encrypt $PWD_FILE --vault-id $VAULT_PASSWORD_FILE
ansible-vault edit $PWD_FILE --vault-id $VAULT_PASSWORD_FILE


