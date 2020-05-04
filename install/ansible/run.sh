#!/bin/bash

ansible-playbook -i inventory -v 01-os-pkgs.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' --tags "os_pkgs_only" -e 'ansible_python_interpreter=/usr/bin/python'
ansible-playbook -i inventory -v 01-mongodb-prereq.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' -e 'ansible_python_interpreter=/usr/bin/python'
ansible-playbook -i inventory -v 01-mongodb-cluster-setup.yml --vault-password-file=.vault.pwd --extra-vars '@sudo-secret' --skip-tags "os_pkgs_upgrade"

