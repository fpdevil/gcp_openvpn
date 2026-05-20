/*
  main.tf
*/

# Set  Standard Tier  as  the default  for all  projects,  unless it  is
# critical like  production. The Standard  Tier does not  support global
# load balancing,  Cloud CDN, or Anycast  IPs. So, If any  such features
# are required,  use Premium Tier  for those specific resources.  We may
# also mix tiers within the same project.
resource "google_compute_project_default_network_tier" "default" {
  project      = var.project_id
  network_tier = "STANDARD"
}

# Create a VM Instance for hosting the OpenVPN software using the VPC &
# Subnet configured
resource "google_compute_instance" "openvpn_vm" {
  name         = var.vm_name
  machine_type = var.machine_type
  zone         = var.zone
  labels       = var.labels

  boot_disk {
    initialize_params {
      # parameters for the new disk alongside the instance
      # image = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2510-questing-amd64-v20260211"
      image = data.google_compute_image.my_image.self_link
      type  = "pd-standard"
      labels = {
        instance = "openvpn-host"
        purpose  = "private-vpn-network"
        region   = var.region
      }
    }
  }

  # attach relevant networks to the VM
  network_interface {
    network    = google_compute_network.main.self_link
    subnetwork = google_compute_subnetwork.public_subnet.self_link

    # Conditionally add an external IP to the VM
    # By default an external IP will be created
    # For a dedicated static public IP, we can specify below value inside
    # access_config block
    # nat_ip = google_compute_address.public_ip.address
    access_config {
      # Ephemral Public IP or a Static IP
      nat_ip = var.need_external_ip ? google_compute_address.static_public_ip[0].address : null
    }
  }

  # Ensure that the firewall rules are provisioned prior to the VM instance
  # provisioning so that SSH does not fail
  depends_on = [
    google_compute_firewall.firewall
  ]

  # list of predefined metadata keys
  metadata = {
    ssh-keys = "${var.username}:${tls_private_key.ssh.public_key_openssh}"
  }

  metadata_startup_script = var.enable_startup_script ? file(local.startup) : null

  tags = [
    for t in var.firewall : t["target_tags"][0]
  ]
}
