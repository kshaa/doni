# Use AWS S3 for Terragrunt state
# https://github.com/gruntwork-io/terragrunt/issues/212
terraform {
  backend "s3" {}
}

# Configure the DigitalOcean Provider
provider "digitalocean" {
  token = "${var.do_token}"
}

# Web server
resource "digitalocean_droplet" "droplet" {
  image  = "ubuntu-18-04-x64"
  name   = "${var.project_code}-london"
  region = "${var.region}"
  size   = "${var.droplet_size}"
  ssh_keys = ["${digitalocean_ssh_key.access_key.fingerprint}"]

  user_data = "${data.template_file.cloud_init.rendered}"
  volume_ids = ["${digitalocean_volume.concourse_volume.id}"]

  # Droplet itself is in a private network
  # See the "Floating IP" below for public access
  ipv6               = true
  private_networking = true
}

# Persistent volume
resource "digitalocean_volume" "concourse_volume" {
  region      = "${var.region}"
  # This name is hardcoded in chef recipes
  name        = "persist" 
  size        = "${var.volume_size}"
  description = "persistent volume (db, docker images, etc.)"
}

# Access key
resource "digitalocean_ssh_key" "access_key" {
  name       = "SSH Access key"
  public_key = "${file("${path.module}/id_rsa.pub")}"
}

# Floating Ip
resource "digitalocean_floating_ip" "droplet_ip" {
  droplet_id = "${digitalocean_droplet.droplet.id}"
  region     = "${digitalocean_droplet.droplet.region}"
}

# Domain setup
resource "digitalocean_domain" "droplet_domain" {
  # Terraform has a weird way to handle conditional resources - count
  count = "${var.domain_exists}"

  name = "${var.domain_name}"
  ip_address = "${digitalocean_floating_ip.droplet_ip.ip_address}"
}

# Initialisation script
data "template_file" "cloud_init" {
  template = "${file("${path.module}/init-cloud/cloud-init-chef-bootstrap.yaml")}"

  vars {
    source = "${var.source}"
    mail_user = "${var.mail_user}"
    mail_pass = "${var.mail_pass}"
    project_code = "${var.project_code}"
    deploy_id = "${file("${path.module}/init-cloud/deploy_id")}"

    # This injects the secrets.env file with indentation of six spaces, because
    # in the cloud init, the yaml syntax there requires an indentation
    # see ./init-cloud/cloud-init.yaml :: ${init-script}
    secrets = "${replace(file("${path.module}/init-cloud/init-script.sh"), "/(?m)^/", "      ")}"
  }
}

resource "null_resource" "deploy_id_generate" {
  provisioner "local-exec" {
    command = "echo `[ $(git rev-parse) ] && echo \"C$(git rev-parse --short HEAD)\" || echo \"D$(date +%s)\"` > ${path.module}/init-cloud/deploy_id"
  }
}

# Return the public (floating) droplet IP
output "droplet_ip" {
  value = "${digitalocean_floating_ip.droplet_ip.ip_address}"
}
