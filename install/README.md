# Sharded MongoDB Cluster - Installation

This section handles setup of the mongodb cluster.
The exploration of the setup is done on digital ocean with CentOS based droplets

## Principal Consideration

- Ease of maintenance using docker
- Support for sharded cluster with each shard being a replica set
- Ease of scaling by easy to add new shard or new instance to a replica set
- Production ready
  - Largely secured

## Prerequisites

The following software are to be installed:

- **Terraform:** Terraform will control or provision servers and load balancer infrastructure in digital ocean. To install it locally, read the _Install Terraform_ section from [Hashicorp Learn website](https://learn.hashicorp.com/terraform/getting-started/install.html)
- **Ansible:** Ansible is used to configure the servers after Terraform has created them. [The official Ansible documentation](https://docs.ansible.com/ansible/latest/intro_installation.html) contains the instructions for installation

**An SSH key set up on your local computer will make it easy to access provisioned droplets**. The public key will be uploaded to the DigitalOcean Control Panel. See tutorial from digital ocean [How To Use SSH Keys with DigitalOcean Droplets](https://www.digitalocean.com/community/tutorials/how-to-use-ssh-keys-with-digitalocean-droplets).

Finally, **a personal access token for the DigitalOcean API** is also needed. To generate a token, folow the reading [How To Use the DigitalOcean API v2](https://www.digitalocean.com/community/tutorials/how-to-use-the-digitalocean-api-v2)

Once the pre-req software, and at least an API token is generated, proceed to the steps below.

## Step 1 - Use terraform to provision droplets (VMs) (cloud only)

Download terraform plugins based on used modules in scripts

```bashrc
# navigate to terraform directory
cd $install/terraform

# run terraform init to download needed terraform plugins
terraform init
```

Fill in token, ssh key, and password used in the `digitalocean.auto.tfvars` file

1. copy `digitalocean.auto.tfvars.sample` to `digitalocean.auto.tfvars`

2. note that all `*.tfvars` files are not version controlled for security reason

3. Fields as follows:
   - **api_token** - digital ocean (personal) api token
   - **ssh_key_name** - name that identifies your ssh public key in digital ocean (just provide a meaningful name e.g. jason_ssh_key)
   - **ssh_key_file** - local file path to your ssh key (default should be `$home_directory/.ssh/id_rsa`)
     - To create ssh key, run `ssh-keygen -t rsa -b 4096`
   - **sysadmin_password** - password hash of os user (sysadmin). sysadmin is the default os user that will be created as part of the terraform provisioning. use `openssl passwd -1 <password>` to generate the hash.

Run terraform to start provisioning

```bashrc
# In terraform (main.tf), infrastructure resources are declared or described with their desired state (i.e. not procedural)

# input yes when prompt
terraform apply
```

After terraform completed, it should create `inventory` file in `ansible` directory

## Step 2 - Ansible for automating mongodb cluster using docker-compose

Generate secret for using ansible vault. Ansible vault is used for handling secret or password at rest. Basically, it encrypts password or secret variables used in ansible automation

We use a bash script to run ansible command for that. In addition, the script will be for specifying the os user and its password

The os user should be `sysadmin` and password should be the same as specified in digitalocean.auto.tfvars (`sysadmin_password`)

```bashrc
# run below script to input ansible secret
cd $install/ansible

./01_generate_vault_n_sudo_pass.sh
```

Set the following secrets and password for mongodb. It will be stored in `group_vars/all/vault`

- **mongo_root_password** - password of default root user account in mongo
- **mongo_auth_scram_key** - authentication keyfile value. This is a secret key for all mongodb instance in the cluster to trust each other. It should be between 6 to 1024 characthers.
- **mongo_monit_user** - username of monitor user account in mongo. This account is used by monitoring tool to access mongo via prometheus
- **mongo_monit_password** - password of monitor user account in mongo.
- **pmm_server_user** - username of account for pmm agent to communicate with pmm server
- **pmm_server_password** - password of account for pmm agent to communicate with pmm server

To set the secrets and passwords, run the following script

```bashrc
# use previously generated ansible vault secret to encrypt the above parameters
./02_generate_vault_4_mongo.sh
```

Configure the setup by modifying the setting in `ansible/group_vars/all/vars.yml` as needed. Here is some settings that you might ar least want to consider changing:

- is_online - indicate if environment is with internet (digital ocean) or air-gapped. The automation will run quite differently depending on this (add different yum repo and docker registry)

- use_hosts_file - set to yes to generate entries on etc/hosts. Generally should not be needed as dns is preferred. In fact, this is discouraged. Note that setting this to yes will also **result in docker containers that run mongodb to use host network instead of the default bridge network**, which might not be desirable. It need to set to host network so that entries in the etc/hosts file can be recognize inside docker containers without explicitly stating each of them in every containers.

For air-gapped environment, please change the following as well:

- os_repos.offline.epel.url - yum repository url for EPEL
- os_repos.offline.docker.url - yum repository url for docker-ce binaries
- docker_registry_host - hostname for private docker registry
- docker_compose_install_url - url for downloading docker compose from artifactory (note that docker compose is not really in use in this setup)

Run ansible to begin automation

```
# run.sh script contains a series of ansible playbooks and actions that it run in sequence
./run.sh
```

## Additional Info

### xip.io

Internet based setup uses `xip.io` domain to avoid the need to setup dns server and entries for mongodb nodes.

On internet accessible network, `xip.io` is a magic domain name that provides wildcard DNS for any IP address. For example, given `mongo-shard-1-1.10.104.0.5.xip.io`, DNS will resolves it to 10.104.0.5.

**How it works**
When your computer looks up a xip.io domain, the xip.io DNS server extracts the IP address from the domain and sends it back in the response.

### Understanding Ansible Inventory for MongoDB cluster

`inventory` file defines how the mongodb-cluster will be structured

```
#inventory file should be in this layout

[TODO: to add on...]

```

## Tear down mongodb cluster (on digital ocean)

Run terraform destroy to remove everything that was created

```
cd $install/terraform

# input yes when prompt
terraform destroy
```
