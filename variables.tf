variable "project_id" {
  type        = string
  description = "Google Project ID"
}

variable "region" {
  type        = string
  description = "Default GCP Region"
}

variable "zone" {
  type        = string
  description = "Default Zone"
}

variable "static_image" {
  type        = string
  description = "A static linux image to be used for creating the VM instances"
}

variable "image_family" {
  type        = string
  description = "The specific linux image family to be used for creating the VM"
}

variable "vm_name" {
  type        = string
  description = "OpenVPN VM Instance"
}

variable "machine_type" {
  type        = string
  description = "Machine Type"
  default     = "e2-micro"
}

variable "vpc_name" {
  type        = string
  description = "OpenVPN VPC to be created"
  default     = "my-vpc"
}

variable "subnet_name" {
  type        = string
  description = "OpenVPN Subnet associated with the VPC created"
  default     = "my-vpc-subnet"
}

variable "cidr_range" {
  type        = string
  description = "Classless Inter-Domain Routing (CIDR) range for the Subnet"
  default     = "10.1.0.0/24"
  validation {
    condition     = can(regex("^(10\\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])|192\\.168\\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9])\\.(?:25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9]?[0-9]))$", var.cidr_range))
    error_message = "Provide proper network address for class 10.a.b.c or 192.168.a.b"
  }
}

variable "netmask" {
  type    = string
  default = "/24"
  validation {
    condition     = can(regex("^\\/(1[6-9]|2[0-4])$", var.netmask))
    error_message = "Please use mask size from /16 to /24."
  }
}

variable "firewall" {
  description = "A list of firewall parameters"
  type        = list(any)
}

variable "need_external_ip" {
  description = "Does the VM need a dedicated Public IP?"
  type        = bool
}

variable "enable_startup_script" {
  type        = bool
  default     = true
  description = "Whether a startup script is used to perform post provision processing"
}

variable "ssh_key_name" {
  description = "File name to save your public/private keys"
  type        = string
  default     = "tf_ssh_key"
}

variable "path" {
  description = "Full path to the folder to save public/private keys"
  type        = string
  default     = "./keys"
}

variable "username" {
  description = "The default username of the EC2 instance launched"
  type        = string
}

variable "labels" {
  description = "List of labels to attach to the VM instance."
  type        = map(any)
}

variable "credentials" {
  description = "GCP Service Account Credentials metadata json file"
  type        = string
}

variable "ovpn_config_dir" {
  description = "The directory where the OVPN configuration file will be downloaded to"
  type        = string
}

