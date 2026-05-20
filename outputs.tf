output "instance_ip_address" {
  description = "External IP address of the VM instance"
  // If static IP is used, output the reserved IP; otherwise, output the ephemeral IP from the instance attributes
  value = var.need_external_ip ? google_compute_address.static_public_ip[0].address : google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip
}

output "internal_ip" {
  description = "Internal IP address of the Instance"
  value       = google_compute_instance.openvpn_vm.network_interface[0].network_ip
}

output "instance_id" {
  description = "Instance ID"
  value       = google_compute_instance.openvpn_vm.instance_id
}

output "self_link" {
  description = "Self link of the instance"
  value       = google_compute_instance.openvpn_vm.self_link
}

output "name" {
  description = "Name of the instance"
  value       = google_compute_instance.openvpn_vm.name
}

output "info" {
  value = data.google_client_openid_userinfo.me
}

output "public_key_openssh" {
  description = "Public Key Information"
  value       = tls_private_key.ssh.public_key_openssh
}

output "private_key_pem" {
  description = "Private Key Information"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "public_key_filepath" {
  description = "Public Key file"
  value       = local.public_key_filename
}

output "private_key_filepath" {
  description = "Private Key file"
  value       = local.private_key_filename
}

output "external_ip" {
  description = "The external IP address of the instance, if assigned"
  value       = var.need_external_ip ? google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip : null
}

output "ssh_login" {
  value = var.need_external_ip ? format("ssh -i %s %s@%s", local.private_key_filename, var.username, google_compute_address.static_public_ip[0].address) : format("ssh -i %s %s@%s", local.private_key_filename, var.username, google_compute_instance.openvpn_vm.network_interface[0].access_config[0].nat_ip)
}