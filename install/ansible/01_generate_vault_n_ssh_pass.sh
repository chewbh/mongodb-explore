#!/bin/bash

create_vault_secret() {
    echo "attempting to create it.."
    echo ""
    read -s -p "vault secret: " VAULT_SECRET

    rm -f .vault.pwd
    echo $VAULT_SECRET > .vault.pwd
    echo ""
    echo ""
    VAULT_SECRET_CREATED=true
}

create_encrypted_sudo_pass() {
    echo "attempting to create it.."
    echo ""
    read -p "os user: " SSH_USER
    read -s -p "password: " SUDO_PASSWORD

    rm -f sudo-secret
    echo "ansible_user: $SSH_USER" > sudo-secret
    echo "ansible_ssh_pass: $SUDO_PASSWORD" >> sudo-secret
    echo "ansible_sudo_pass: $SUDO_PASSWORD" >> sudo-secret
    echo ""
    ansible-vault encrypt --vault-password-file .vault.pwd sudo-secret
}

if [ ! -f .vault.pwd ]; then
    echo "vault secret is not found"
    create_vault_secret
else
    if [ "$1" == "overwrite" ]; then
        echo "requested for overwriting existing secret.."
        create_vault_secret
    fi
fi

if [ ! -f sudo-secret ]; then
    echo "encrypted password of sudo user to access node is not found"
    create_encrypted_sudo_pass
else
    if [ ! -z $VAULT_SECRET_CREATED ]; then
        echo "requested for overwriting sudo account's password to access node.."
        create_encrypted_sudo_pass
    else
        echo "encrypted password of sudo user to access node already exists"
        echo "no action to be taken"
    fi
fi

