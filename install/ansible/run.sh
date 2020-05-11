#!/bin/bash

## download and install os packages needed as part of ansible run (--tags "os_pkgs_only")
## standard node setup
ansible-playbook -i inventory -v 01-standard-node.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' --skip-tags "os_pkgs_upgrade" -e 'ansible_python_interpreter=/usr/bin/python2'
ansible-playbook -i inventory -v 01-mongodb-prereq.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' -e 'ansible_python_interpreter=/usr/bin/python2'

# run actual cluster setup (exclude monitoring / pmm-agent if flag not on)
ansible-playbook -i inventory -v 01-mongodb-cluster-setup.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret'

# run script to create cluster and account
# add new scripts here if needed..

# re-run setup (this time with flag on - ensure monitoring / pmm-agent  is setup)
ansible-playbook -i inventory -v 01-mongodb-cluster-setup.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' --extra-vars "pmm_agent_setup=true|bool"


