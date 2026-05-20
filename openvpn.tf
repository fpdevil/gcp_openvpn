resource "null_resource" "bootstrap_openvpn" {
  # Specify any triggers as needed
  triggers = {}

  # Define connection details for remote provisioner
  connection {
    type        = "ssh"                                                                           # connection type
    user        = var.username                                                                    # username for authentication
    host        = google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip # external IP of VM
    timeout     = "500s"                                                                          # connection timeout
    private_key = file(local.private_key_filename)                                                # private key for ssh
  }

  # Define file provisioner to copy the scripts from local to remote VM
  provisioner "file" {
    source      = local.openvpn
    destination = local.bootstrap
  }

  # Define remote-exec provisioner to execute commands on the remote host
  provisioner "remote-exec" {
    inline = [
      "chmod +x ${local.bootstrap}",
      "bash ${local.bootstrap}"
    ]

    on_failure = continue
  }
}

resource "null_resource" "download_openvpn_configuration" {
  depends_on = [
    google_compute_instance.openvpn_vm,
    null_resource.bootstrap_openvpn
  ]

  # Trigger this resource when instance IP changes
  triggers = {
    instance_ip = google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip
    ovpn_file   = "${local.openvpn_file}" # Store filename in triggers
  }

  # Wait for OpenVPN installation to complete and file to be created
  provisioner "remote-exec" {
    inline = [
      "while [ ! -f /home/${var.username}/${local.openvpn_file} ]; do sleep 20; echo 'Waiting for OpenVPN config file...'; done",
      "echo 'OpenVPN config file is ready!'"
    ]

    # Define connection details for remote provisioner
    connection {
      type        = "ssh"                                                                           # connection type
      user        = var.username                                                                    # username for authentication
      host        = google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip # external IP of VM
      timeout     = "500s"                                                                          # connection timeout
      private_key = file(local.private_key_filename)                                                # private key for ssh
    }
  }

  provisioner "local-exec" {
    command = <<EOT
      mkdir -p ${var.ovpn_config_dir};
      scp -o StrictHostKeyChecking=no \
          -o UserKnownHostsFile=/dev/null \
          -i ${local.private_key_filename} ${var.username}@${google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip}:/home/${var.username}/${local.openvpn_file} ./${var.ovpn_config_dir}/
    EOT
  }
}
