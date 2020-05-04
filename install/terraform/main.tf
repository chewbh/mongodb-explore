variable "api_token" {}
variable "ssh_key_name" {}
variable "ssh_key_file" {}
variable "sysadmin_password" {}

provider "digitalocean" {
  token = var.api_token
}

resource "digitalocean_ssh_key" "local" {
  name       = var.ssh_key_name
  public_key = file("${var.ssh_key_file}.pub")
}

# create the VMs for mongos
resource "digitalocean_droplet" "mongos" {
  count    = 2
  image    = "centos-7-x64"
  name     = "mongos-${count.index + 1}"
  region   = "sgp1"
  size     = "s-4vcpu-8gb"
  ipv6     = false
  tags     = ["mongodb", "mongos"]
  ssh_keys = [digitalocean_ssh_key.local.id]

  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.ssh_key_file)
    timeout     = "2m"
  }

  # add admin user, set password, and enable ssh access via password
  provisioner "remote-exec" {
    inline = [
      "sudo adduser sysadmin",
      "sudo echo ${var.sysadmin_password} | sudo passwd --stdin sysadmin",
      "sudo usermod -aG wheel sysadmin",
      "sudo sed -i '/^[^#]*PasswordAuthentication[[:space:]]no/c\\PasswordAuthentication yes' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }
}

# create the VMs for config servers
resource "digitalocean_droplet" "config_servers" {
  count    = 3
  image    = "centos-7-x64"
  name     = "cfgsvr-${count.index + 1}"
  region   = "sgp1"
  size     = "s-4vcpu-8gb"
  ipv6     = false
  tags     = ["mongodb", "cfgsvr"]
  ssh_keys = [digitalocean_ssh_key.local.id]

  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.ssh_key_file)
    timeout     = "2m"
  }

  # add admin user, set password, and enable ssh access via password
  provisioner "remote-exec" {
    inline = [
      "sudo adduser sysadmin",
      "sudo echo ${var.sysadmin_password} | sudo passwd --stdin sysadmin",
      "sudo usermod -aG wheel sysadmin",
      "sudo sed -i '/^[^#]*PasswordAuthentication[[:space:]]no/c\\PasswordAuthentication yes' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }
}

# create the VMs for mongo shard 1
resource "digitalocean_droplet" "mongo_shard_1" {
  count    = 2
  image    = "centos-7-x64"
  name     = "mongo-shard-1-${count.index + 1}"
  region   = "sgp1"
  size     = "s-4vcpu-8gb"
  ipv6     = false
  tags     = ["mongodb", "app01RS"]
  ssh_keys = [digitalocean_ssh_key.local.id]

  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.ssh_key_file)
    timeout     = "2m"
  }

  # add admin user, set password, and enable ssh access via password
  provisioner "remote-exec" {
    inline = [
      "sudo adduser sysadmin",
      "sudo echo ${var.sysadmin_password} | sudo passwd --stdin sysadmin",
      "sudo usermod -aG wheel sysadmin",
      "sudo sed -i '/^[^#]*PasswordAuthentication[[:space:]]no/c\\PasswordAuthentication yes' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }
}

# create the VMs for mongo shard 2
resource "digitalocean_droplet" "mongo_shard_2" {
  count    = 2
  image    = "centos-7-x64"
  name     = "mongo-shard-2-${count.index + 1}"
  region   = "sgp1"
  size     = "s-4vcpu-8gb"
  ipv6     = false
  tags     = ["mongodb", "app02RS"]
  ssh_keys = [digitalocean_ssh_key.local.id]

  connection {
    user        = "root"
    type        = "ssh"
    host        = self.ipv4_address
    private_key = file(var.ssh_key_file)
    timeout     = "2m"
  }

  # add admin user, set password, and enable ssh access via password
  provisioner "remote-exec" {
    inline = [
      "sudo adduser sysadmin",
      "sudo echo ${var.sysadmin_password} | sudo passwd --stdin sysadmin",
      "sudo usermod -aG wheel sysadmin",
      "sudo sed -i '/^[^#]*PasswordAuthentication[[:space:]]no/c\\PasswordAuthentication yes' /etc/ssh/sshd_config",
      "sudo systemctl restart sshd"
    ]
  }
}

# configure firewall that only accepts ssh and port 27017 traffic
resource "digitalocean_firewall" "mongodb-firewall" {
  name = "mongodb-firewall"

  droplet_ids = digitalocean_droplet.mongos.*.id

  # allow ssh connection via port 22 to VMs / droplets
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  # allow mongodb connection via port 27017
  inbound_rule {
    protocol         = "tcp"
    port_range       = "27017"
    source_addresses = ["0.0.0.0/0"]
    # source_load_balancer_uids = [digitalocean_loadbalancer.lb.id]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "all"
    destination_addresses = ["0.0.0.0/0"]
  }
}

locals {
  # assign 2nd element of each shard as arbiter of the other shard manually
  mongo_shard_1 = list(
    merge(element(digitalocean_droplet.mongo_shard_1, 0), { "arbiter_replica_set_name" = "" }),
    merge(element(digitalocean_droplet.mongo_shard_1, 1), { "arbiter_replica_set_name" = "app02RS" })
  )
  mongo_shard_2 = list(
    merge(element(digitalocean_droplet.mongo_shard_2, 0), { "arbiter_replica_set_name" = "" }),
    merge(element(digitalocean_droplet.mongo_shard_2, 1), { "arbiter_replica_set_name" = "app01RS" })
  )
}

# create an ansible inventory file for subsequently automation
resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.module}/ansible-inventory.tmpl",
    {
      mongos         = digitalocean_droplet.mongos,
      config_servers = digitalocean_droplet.config_servers,
      mongo_shard_1  = local.mongo_shard_1,
      mongo_shard_2  = local.mongo_shard_2
  })
  file_permission = "0664"
  filename        = "../ansible/inventory"
}
