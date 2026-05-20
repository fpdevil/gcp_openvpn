# Manages a VPC network
resource "google_compute_network" "main" {
  name                    = var.vpc_name
  description             = "VPC for OpenVPN project"
  project                 = var.project_id
  auto_create_subnetworks = false
}

# Create a Regional Subnet under the VPC network
# Each  VPC network  is  subdivided  into subnets,  and  each subnet  is
# contained within a single region. We  can have more than one subnet in
# a region for  a given VPC network. All the  instances, containers, and
# the like are created in these  subnets. When we create an instance, it
# must be  created in a subnet,  and the instance draws  its internal IP
# address from that subnet.
# Virtual machine (VM)  instances in a VPC network  can communicate with
# instances in all other subnets of  the same VPC network, regardless of
# region, using their private IP addresses.
resource "google_compute_subnetwork" "public_subnet" {
  name          = var.subnet_name
  ip_cidr_range = "${var.cidr_range}${var.netmask}"
  region        = var.region
  network       = google_compute_network.main.self_link

  # Don't need  public subnet to  have private google access,  but in
  # such case,  if we want to  reach Google API's, the  calls will be
  # routed via Cloud NAT which  costs some amount. Keeping this value
  # as "true"  will let the  VM reach  Google API's directly  free of
  # cost
  private_ip_google_access = false
}

# External IP addresses can be either ephemeral or static and
# this resource block creates a Public IP for our instance to connect
resource "google_compute_address" "static_public_ip" {
  count   = var.need_external_ip ? 1 : 0
  name    = "vm-static-publicip"
  project = var.project_id
  region  = var.region
  depends_on = [
    google_compute_firewall.firewall
  ]
}
