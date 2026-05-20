/*
  Creation of the key pairs for connecting to GCP instance
*/

resource "null_resource" "directory_for_keys" {
  provisioner "local-exec" {
    command = <<EOT
      #!/bin/bash
      if [ ! -d ${var.path} ]; then
        echo 'Creating directory ${var.path}'
        mkdir -p ${var.path}
      else
        echo "${var.path} already exists"
      fi
    EOT
  }
}

# Resource: Creates a PEM (and OpenSSH) formatted SSH Private Key
# The public key generated here will be used for the GCP key pairs
# https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Resource: Generate a CSR
resource "tls_cert_request" "csr" {
  private_key_pem = tls_private_key.ssh.private_key_pem

  subject {
    common_name         = "personalvpn.terraform.com"
    organizational_unit = "Technology"
    organization        = "OpenVPN project"
    street_address      = ["Street name"]
    locality            = "City name"
    province            = "State name"
    country             = "US"
    postal_code         = "12345"
  }
}

# Resource: Generates a local file with the given content
# Here, public key file is created with content from "tls_private_key"
# https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/file
resource "local_file" "public_key" {
  depends_on      = [tls_private_key.ssh, null_resource.directory_for_keys]
  content         = tls_private_key.ssh.public_key_openssh
  filename        = local.public_key_filename
  file_permission = "0600"
}

# Resource: Generates a local file with the given sensitive content
# Here, private key file is created with content from "tls_private_key"
# https://registry.terraform.io/providers/hashicorp/local/latest/docs/resources/sensitive_file
resource "local_sensitive_file" "private_key" {
  depends_on      = [tls_private_key.ssh, null_resource.directory_for_keys]
  content         = tls_private_key.ssh.private_key_pem
  filename        = local.private_key_filename
  file_permission = "0600"
}
