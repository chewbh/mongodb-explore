#!/bin/bash

## download and install os packages needed as part of ansible run (--tags "os_pkgs_only")
ansible-playbook -i inventory -v 01-mongodb-cluster-setup.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' --extra-vars 'docker_container_remove=yes' --extra-vars "pmm_agent_setup=true|bool" --tags='all, wipe_data'

