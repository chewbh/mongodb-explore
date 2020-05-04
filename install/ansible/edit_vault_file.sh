#!/bin/bash

export EDITOR=vim
ansible-vault edit --vault-password-file .vault.pwd $1