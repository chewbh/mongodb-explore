#!/bin/bash


create_encrypted_vault_file() {
    echo "attempting to create vault file.."
    echo ""
    read -s -p "mongo_root_password: " MONGO_ROOT_PASSWORD
    echo ""
    read -s -p "mongo_auth_scram_key (6 to 1024 alphanumeric chars): " AUTH_SCRAM_KEY 
    echo ""
    read -p "mongo_monit_user(root): " MONGO_MONIT_USER
    echo ""
    read -s -p "mongo_monit_password: " MONGO_MONIT_PASSWORD
    echo ""
    read -p "pmm_server_user(admin): " PMM_SERVER_USER
    echo ""
    read -s -p "pmm_server_password(admin): " PMM_SERVER_PASSWORD
    echo ""

    rm -f group_vars/all/vault
    echo "mongo_root_password: $MONGO_ROOT_PASSWORD" > group_vars/all/vault
    echo "mongo_auth_scram_key: $AUTH_SCRAM_KEY" >> group_vars/all/vault
    echo "mongo_monit_user: ${MONGO_MONIT_USER:-"root"}" >> group_vars/all/vault
    echo "mongo_monit_password: $MONGO_MONIT_PASSWORD" >> group_vars/all/vault
    echo "pmm_server_user: ${PMM_SERVER_USER:-"admin"}" >> group_vars/all/vault
    echo "pmm_server_password: ${PMM_SERVER_PASSWORD:-"admin"}" >> group_vars/all/vault
    echo ""
    ansible-vault encrypt --vault-password-file .vault.pwd group_vars/all/vault
}

if [ ! -f .vault.pwd ]; then
    echo "vault secret is not found. please run ./generate_vault_n_sudo_pass.sh first"
    exit 1
fi

if [ ! -f group_vars/all/vault ]; then
    echo "group_vars/all/vault file exists. It will be recreated."
fi

create_encrypted_vault_file

