resource "google_compute_firewall" "firewall" {
  count = length(var.firewall)

  name        = "${google_compute_network.main.name}-${var.firewall[count.index]["name"]}"
  description = var.firewall[count.index]["description"]

  # Associate the firewall rule with the VPC network created earlier
  network = google_compute_network.main.self_link

  allow {
    protocol = var.firewall[count.index]["allow"]["protocol"]
    ports    = var.firewall[count.index]["allow"]["ports"]
  }

  # Direction to apply firewall
  direction = var.firewall[count.index]["direction"]

  # The source IP range that allowed to access
  source_ranges = var.firewall[count.index]["source_ranges"]

  priority    = var.firewall[count.index]["priority"]
  target_tags = var.firewall[count.index]["target_tags"]
}
