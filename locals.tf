# All local variables for usage within the configuration
locals {
  # use same file name with different extensions for easiness
  public_key_filename  = "${var.path}/${var.ssh_key_name}.pub" # public key
  private_key_filename = "${var.path}/${var.ssh_key_name}.pem" # private key

  # scripts
  openvpn   = "${path.module}/scripts/ovpn.sh"
  startup   = "${path.module}/scripts/startup.sh"
  bootstrap = "/home/${var.username}/ovpn.sh"

  # openvpn configuration file created
  openvpn_file = "${var.username}.ovpn"
}
