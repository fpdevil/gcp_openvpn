# This block configures Terraform itself, including which providers to install
# and which version of Terraform to use to provision out infrastructure.
# It is recommended to maintain this in a dedicated terraform.tf file
terraform {
  # required terraform version
  required_version = "~>1.14"

  # select the provider version
  # source contains address of the provider in the Terraform Registry.
  # here "hashicorp/gcp" is shortened form of "registry.terraform.io/hashicorp/aws"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>7.20"
    }

    tls = {
      source  = "hashicorp/tls"
      version = "~>4.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "~>2.6"
    }
  }
}
