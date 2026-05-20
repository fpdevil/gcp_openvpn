provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.credentials)
}

# TLS provider provides utilities for working with TLS keys and Certificates.
provider "tls" {}

# null_resource implements the standard resource lifecycle but takes no further action
provider "null" {}

# Local provider is used to manage local resources, such as files
provider "local" {}

# Datasource: Get OpenID userinfo about the credentials used with the
# Google provider, specifically the email.
data "google_client_openid_userinfo" "me" {}
