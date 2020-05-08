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

resource "digitalocean_domain" "default" {
  name = "thor1.test"
}

# data "dns_a_record_set" "ns1_digitalocean" {
#   host = "ns1.digitalocean.com"
# }
# data "dns_a_record_set" "ns2_digitalocean" {
#   host = "ns2.digitalocean.com"
# }
# data "dns_a_record_set" "ns3_digitalocean" {
#   host = "ns3.digitalocean.com"
# }

# resource "digitalocean_record" "mongos_a" {
#   count  = length(digitalocean_droplet.mongos)
#   domain = digitalocean_domain.default.name
#   type   = "A"
#   name   = element(digitalocean_droplet.mongos.*.name, count.index)
#   value  = element(digitalocean_droplet.mongos.*.ipv4_address_private, count.index)
# }

# create the VMs for mongos
resource "digitalocean_droplet" "mongos" {
  count              = 2
  image              = "centos-7-x64"
  name               = "mongos-${count.index + 1}"
  region             = "sgp1"
  size               = "s-4vcpu-8gb"
  ipv6               = false
  tags               = ["mongodb", "mongos"]
  ssh_keys           = [digitalocean_ssh_key.local.id]
  private_networking = true
  user_data = templatefile("${path.module}/cloud-config.yaml", {
    domain            = digitalocean_domain.default.name
    sysadmin_password = var.sysadmin_password
  })
}

# create the VMs for config servers
resource "digitalocean_droplet" "config_servers" {
  count              = 3
  image              = "centos-7-x64"
  name               = "cfgsvr-${count.index + 1}"
  region             = "sgp1"
  size               = "s-4vcpu-8gb"
  ipv6               = false
  tags               = ["mongodb", "cfgsvr"]
  ssh_keys           = [digitalocean_ssh_key.local.id]
  private_networking = true
  user_data = templatefile("${path.module}/cloud-config.yaml", {
    domain            = digitalocean_domain.default.name
    sysadmin_password = var.sysadmin_password
  })
}

# create the VMs for mongo shard 1
resource "digitalocean_droplet" "mongo_shard_1" {
  count              = 2
  image              = "centos-7-x64"
  name               = "mongo-shard-1-${count.index + 1}"
  region             = "sgp1"
  size               = "s-4vcpu-8gb"
  ipv6               = false
  tags               = ["mongodb", "app01RS"]
  ssh_keys           = [digitalocean_ssh_key.local.id]
  private_networking = true
  user_data = templatefile("${path.module}/cloud-config.yaml", {
    domain            = digitalocean_domain.default.name
    sysadmin_password = var.sysadmin_password
  })
}

# create the VMs for mongo shard 2
resource "digitalocean_droplet" "mongo_shard_2" {
  count              = 2
  image              = "centos-7-x64"
  name               = "mongo-shard-2-${count.index + 1}"
  region             = "sgp1"
  size               = "s-4vcpu-8gb"
  ipv6               = false
  tags               = ["mongodb", "app02RS"]
  ssh_keys           = [digitalocean_ssh_key.local.id]
  private_networking = true
  user_data = templatefile("${path.module}/cloud-config.yaml", {
    domain            = digitalocean_domain.default.name
    sysadmin_password = var.sysadmin_password
  })
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
  }

  # allow all tcp connection in private network
  inbound_rule {
    protocol         = "tcp"
    port_range       = "all"
    source_addresses = ["10.104.0.0/20"]
  }

  # allow all tcp connection in private network
  inbound_rule {
    protocol         = "udp"
    port_range       = "all"
    source_addresses = ["10.104.0.0/20"]
  }

  # allow all icmp connection in private network
  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
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
    merge(element(digitalocean_droplet.mongo_shard_1, 0), { "arbiter_for_replica_set" = "" }),
    merge(element(digitalocean_droplet.mongo_shard_1, 1), { "arbiter_for_replica_set" = "mongo_shard_2" })
  )
  mongo_shard_2 = list(
    merge(element(digitalocean_droplet.mongo_shard_2, 0), { "arbiter_for_replica_set" = "" }),
    merge(element(digitalocean_droplet.mongo_shard_2, 1), { "arbiter_for_replica_set" = "mongo_shard_1" })
  )
}

# create an ansible inventory file for subsequently automation
resource "local_file" "ansible_inventory" {
  content = templatefile(
    "${path.module}/ansible-inventory.tmpl",
    {
      domain         = "xip.io"
      mongos         = digitalocean_droplet.mongos,
      config_servers = digitalocean_droplet.config_servers,
      mongo_shard_1  = local.mongo_shard_1,
      mongo_shard_2  = local.mongo_shard_2
  })
  file_permission = "0664"
  filename        = "../ansible/inventory"
}
