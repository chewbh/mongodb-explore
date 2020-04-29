#!/bin/bash

# =============================================
# generate encrypted config for os user account
# =============================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && PWD)"
PASSWORD_FILE_TEMPLATE=$DIR/group_vars/all/os_user_template.yml
PASSWORD_FILE_LOC=$DIR/group_vars/all/os_user.yml

source $DIR/encrypt.sh $PASSWORD_FILE_TEMPLATE $PASSWORD_FILE_LOC


