#!/bin/bash

## download and install os packages needed as part of ansible run (--tags "os_pkgs_only")
## standard node setup
#ansible-playbook -i inventory -v 01-standard-node.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' --skip-tags "os_pkgs_upgrade" -e 'ansible_python_interpreter=/usr/bin/python2'
#ansible-playbook -i inventory -v 01-mongodb-prereq.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' -e 'ansible_python_interpreter=/usr/bin/python2'
ansible-playbook -i inventory -v 01-mongodb-cluster-setup.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret'

