# DigitalOcean Nixos Infected
A Digital Ocean droplet deployment with NixOS infect.

Actually most of this code is completely unnecessary.
I wanted to send myself an email as a part of the deployment process
and I ended up writing it quite nicely, unfortunately the cloud-init
initialisation bash script gets killed as a part of the nixos-infect
process, so most of this is useless.

The proper way to send myself an email would possibly be by including
that at the end of the actual nix configuration.

Either way, while writing this I had some fun with Terraform, so all is good.
