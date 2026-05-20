# Personal VPN with OpenVPN on GCP using Terraform
The configuration provided will be helpful to quickly provision infrastructure on `GCP` with a personal `VPN` in a region supported by the cloud provider.

Thanks to [Angristan](https://github.com/angristan/openvpn-install) for providing an automation script to setup `openvpn`. This is used as a part of `remote-exec` for setting up `vpn` on remote virtual instance.

## GCP Service Account configuration
We can create a service account on google cloud and then download the `key` file interactively via the `web console` or `gcloud` commands. To keep it simple, the account may be given a broad role of `editor` which might violate the security principle of of least privilege.

First, login and set the project name

```sh
# do authentication via auth code
gcloud auth login --no-launch-browser

# get list of available projects
gcloud projects list

# set the project id of choice in gcloud config
gcloud config set project <PROJECT_ID>
gcloud auth application-default set-quota-project <PROJECT_ID>

# Export the project id into a variable
GOOGLE_CLOUD_PROJECT=`gcloud info --format="value(config.project)"`
```

### Create the `IAM` service account
Create an `IAM` service account to use and set the value to an environment variable.

```bash
# Get Project ID using below command
gcloud config get-value project

# Create Service Account
gcloud iam service-accounts create terraform-sa \
    --description="Terraform IaC Service Account for Infrastructure Creation" \
    --display-name="Terraform Service Account" \
    --project=${GOOGLE_CLOUD_PROJECT}

# returns something like below
#
# Created service account [terraform-sa].
```

Once the `IAM` service account is created, we can create an environment variable `GOOGLE_SERVICE_ACCOUNT` and assign the value of service account to it as demonstrated below:

```bash
# Check service accounts list
gcloud iam service-accounts list

# should return similar to below
# DISPLAY NAME                            EMAIL                                               DISABLED
# Compute Engine default service account  3XXXXXXXXXX7-compute@developer.gserviceaccount.com  False
# terraform                               terraform@sammy-20688.iam.gserviceaccount.com       False

# We can use filters to prune the value
gcloud iam service-accounts list --format="value(email)" --filter=name:"terraform"

# returns something like below
# terraform@sammy-20688.iam.gserviceaccount.com
```

The filtered service account value can be placed inside a variable `GOOGLE_SERVICE_ACCOUNT` as shown below:

```bash
# Export value of service account into a variable
GOOGLE_SERVICE_ACCOUNT=`gcloud iam service-accounts list --format="value(email)" --filter=name:"terraform"`
```

### Grant Service Account Permissions
Service accounts by default do not carry any permissions, so appropriate `IAM` roles need to be granted to the service account in order to use the same.

```bash
# Common roles for Terraform - add roles to policy
# Project-level roles
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/compute.admin"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/storage.admin"

gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/iam.serviceAccountUser"

# If Terraform needs to manage IAM bindings
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/secretmanager.admin"

# If Service account needs access to Secret Manager Admin
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/resourcemanager.projectIamAdmin"

# If managing GKE clusters
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/container.admin"

# If managing Cloud SQL
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/cloudsql.admin"
```

It should return something like below
```text
Updated IAM policy for project [xxxxxxxxx].
bindings:
- members:
  - serviceAccount:terraform-sa@xxxxxxxxx.iam.gserviceaccount.com
  role: roles/compute.admin
- members:
  - serviceAccount:terraform-sa@xxxxxxxxx.iam.gserviceaccount.com
  role: roles/iam.serviceAccountUser
- members:
  - user:sxxxxxxxxxx.sxxxxxx@gmail.com
  role: roles/owner
- members:
  - serviceAccount:terraform-sa@xxxxxxxxx.iam.gserviceaccount.com
  role: roles/resourcemanager.projectIamAdmin
- members:
  - serviceAccount:terraform-sa@xxxxxxxxx.iam.gserviceaccount.com
  role: roles/storage.admin
etag: BwZPXqrhhks=
version: 1
```

For a general-purpose Terraform service account, we might use the `editor role` during initial setup and tighten it later.
```bash
# Only editor role
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
       --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
       --role="roles/editor"
```


If we need to manage `GCS` also through `Terraform` using the same service account, we can grant the _storage admin_ role too as shown below:
```sh
# adding storage.admin role
gcloud projects add-iam-policy-binding $GOOGLE_CLOUD_PROJECT \
    --member="serviceAccount:$GOOGLE_SERVICE_ACCOUNT" \
    --role="roles/storage.admin"
```

Enable the below services if not already enabled:
```sh
gcloud services enable cloudresourcemanager.googleapis.com
gcloud services enable storage.googleapis.com
```

Inorder to view all the roles allocated for the service account, we can use the below command:
```bash
# list all roles associated with a gcp service account
gcloud projects get-iam-policy $PROJECT_ID \--flatten="bindings[].members" \
    --format='table(bindings.role)' \
    --filter="bindings.members:${GOOGLE_SERVICE_ACCOUNT}"

# Response
ROLE
roles/compute.admin
roles/iam.serviceAccountUser
roles/resourcemanager.projectIamAdmin
roles/secretmanager.admin
roles/storage.admin
```

### Generate Service Account Key for authentication
Create keys file for referencing from within the `Terraform` code
```bash
# Create a key and store it inside file `terraform.json`
gcloud iam service-accounts keys create "./terraform-sa.json" --iam-account=$GOOGLE_SERVICE_ACCOUNT

# It should an output similar to below
# created key [52bfd8bdcdb70435c3c4d622003d7acf4e0ccaed] of type [json] as [./terraform.json] for [terraform@sammy-20688.iam.gserviceaccount.com]

# Now activate the Service account
gcloud auth activate-service-account --key-file=terraform-sa.json

# Output format
# Activated service account credentials for: [terraform@sammy-20688.iam.gserviceaccount.com]

# Listing will show the new key now
λ gcloud iam service-accounts keys list --iam-account=$GOOGLE_SERVICE_ACCOUNT
API [iam.googleapis.com] not enabled on project [398403452459]. Would you like to enable and retry (this will take a few
minutes)? (y/N)?  y

Enabling service [iam.googleapis.com] on project [398403452459]...
Operation "operations/acat.p2-398403452459-a9b96c54-9ff0-41b3-9bd4-b46df7f5276a" finished successfully.
KEY_ID                                    CREATED_AT            EXPIRES_AT            DISABLED  DISABLE_REASON  EXTENDED_STATUS
4f36d8c230200514e533161459f6789f90f7475f  2025-09-30T19:58:19Z  9999-12-31T23:59:59Z
d184d86e7ada7f8e234bd3c076073f9be08f70b7  2025-09-30T19:51:41Z  2027-10-15T05:34:16Z

# List the keys for IAM Account
gcloud iam service-accounts keys list --iam-account=$GOOGLE_SERVICE_ACCOUNT

# output will be similar to below
# KEY_ID                                    CREATED_AT            EXPIRES_AT            DISABLED  DISABLE_REASON  EXTENDED_STATUS
# 1d5ac5facbba6bb1cf9033e3bdad4f7aaf5371db  2025-05-03T04:11:37Z  2027-05-09T10:49:23Z
```

#### Login

```bash
gcloud auth application-default login --no-launch-browser
Go to the following link in your browser, and complete the sign-in prompts:

    https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=764086051850-6qr4p6gpi6hn506pt8ejuq83di341hur.apps.googleusercontent.com&redirect_uri=https%3A%2F%2Fsdk.cloud.google.com%2Fapplicationdefaultauthcode.html&scope=openid+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fuserinfo.email+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fcloud-platform+https%3A%2F%2Fwww.googleapis.com%2Fauth%2Fsqlservice.login&state=LzarXuhzOukC5kdTIiA1dFBesxgF9V&prompt=consent&token_usage=remote&access_type=offline&code_challenge=WlT9luWlg5UeoT9jwqa0iOK2D5iOwoK7YIYYUHS9X0Y&code_challenge_method=S256

Once finished, enter the verification code provided in your browser: 4/0Aci98E8T8t6-4c3L40ZwyQtoZIj08VRyCUPxNYorVkWTGE6NzYE7i_aZKNLXHnCiXFIMbQ

Credentials saved to file: [/Users/sampathsingamsetty/.config/gcloud/application_default_credentials.json]

These credentials will be used by any library that requests Application Default Credentials (ADC).

Quota project "xxxxxxxxx" was added to ADC which can be used by Google client libraries for billing and quota. Note that some services may still bill the project owning the resource.
```

## Terraform variables
Configure the values for `IaC` provisioning in `terraform.tfvars` file as per the contract defined in `variables.tf`.

```terraform
# All the inputs to variables
project_id            = "insbhairava"
credentials           = "./sakey.json"
static_image          = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2510-questing-amd64-v20260211"
image_family          = "ubuntu-minimal-2510-amd64"
vm_name               = "openvpnsvr"
region                = "asia-south1"
zone                  = "asia-south1-a"
vpc_name              = "openvpn-vpc"
subnet_name           = "openvpn-public-subnet"
cidr_range            = "10.0.1.0"
netmask               = "/24"
need_external_ip      = false
enable_startup_script = true
machine_type          = "e2-micro"
ssh_key_name          = "gl_ssh_key"
path                  = "keys"
ovpn_config_dir       = "ovpn"
username              = "ubuntu"
firewall = [
  {
    "name" : "allow-ping",
    "description" : "Allow ICMP Ping",
    "direction" : "INGRESS",
    "allow" : {
      "protocol" : "icmp",
      "ports" : []
    },
    "priority" : 65534,
    "source_ranges" : ["0.0.0.0/0"],
    "target_tags" : ["allow-ping"],
  },
  {
    "name" : "allow-ssh",
    "description" : "Allow Remote SSH Access",
    "direction" : "INGRESS",
    "allow" : {
      "protocol" : "TCP",
      "ports" : ["22"]
    },
    "priority" : 1000,
    "source_ranges" : ["0.0.0.0/0"],
    "target_tags" : ["allow-ssh"],
  },
  {
    "name" : "allow-http",
    "description" : "Allow HTTP and Web Access",
    "direction" : "INGRESS",
    "allow" : {
      "protocol" : "TCP",
      "ports" : ["80"]
    },
    "priority" : 1000,
    "source_ranges" : ["0.0.0.0/0"],
    "target_tags" : ["allow-http"],
  },
  {
    "name" : "allow-https",
    "description" : "Allow HTTPS Access",
    "direction" : "INGRESS",
    "allow" : {
      "protocol" : "TCP",
      "ports" : ["443"]
    },
    "priority" : 1000,
    "source_ranges" : ["0.0.0.0/0"],
    "target_tags" : ["allow-http"],
  },
  {
    "name" : "allow-mgmt",
    "description" : "Allow Access to OpenVPN Management Port",
    "direction" : "INGRESS",
    "allow" : {
      "protocol" : "TCP",
      "ports" : ["943"]
    },
    "priority" : 1000,
    "source_ranges" : ["0.0.0.0/0"],
    "target_tags" : ["allow-mgmt"],
  },
  {
    "name" : "allow-openvpn",
    "description" : "Allow OpenVPN on UDP",
    "direction" : "INGRESS",
    "allow" : {
      "protocol" : "UDP",
      "ports" : ["1194"]
    },
    "priority" : 1000,
    "source_ranges" : ["0.0.0.0/0"],
    "target_tags" : ["allow-http"],
  }
]
labels = {
  "environment" = "sandbox"
  "owner"       = "sam"
  "application" = "openvpn"
}
```

## Run Terraform
Once `terraform` is run using the above information, `ssh` keys for remote access under local fodler `keys` as well as `openvpn` configuration file with `.ovpn` extension will be created under a local folder `ovpn`.

```bash
λ terraform apply -auto-approve
data.google_client_openid_userinfo.me: Reading...
data.google_compute_image.my_image: Reading...
data.google_compute_zones.available: Reading...
data.google_client_openid_userinfo.me: Read complete after 0s [id=terraform@insbhairava.iam.gserviceaccount.com]
data.google_compute_image.my_image: Read complete after 0s [id=projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2510-questing-amd64-v20260517]
data.google_compute_zones.available: Read complete after 0s [id=projects/insbhairava/regions/asia-south1]

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following
symbols:
  + create

Terraform will perform the following actions:
...
...
...
Apply complete! Resources: 17 added, 0 changed, 0 destroyed.

Outputs:

compute_zones = tolist([
  "asia-south1-a",
  "asia-south1-b",
  "asia-south1-c",
])
info = {
  "email" = "terraform@insbhairava.iam.gserviceaccount.com"
  "id" = "terraform@insbhairava.iam.gserviceaccount.com"
}
instance_id = "8338442458595610315"
instance_ip_address = "35.207.205.217"
internal_ip = "10.0.1.2"
name = "openvpnsvr"
private_key_filepath = "keys/gl_ssh_key.pem"
private_key_pem = <sensitive>
public_key_filepath = "keys/gl_ssh_key.pub"
public_key_openssh = <<EOT
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQCX8MUe2c5S/iDS6DMOMHnQLPxYhXZQCtvMuUn7oSL45EVcvk+DLmegYYnXh+NdAcOX+at0UfETZcWo4SO1YaMuHeMgnxro9JwzVmuhB0cubdpVTSIT1/KrMonqJCtBL/gu3R076S/QrwW/EeC9icIRK/8L9qzIpQoi266o/5/LKNRUHvvw3W2zmjRXQesffrDqCJUSpHq1rsObuW2enulKkAZQXm5WytkUDNgjUcGS4VesDzWuAHoOixcbYl367uX9IEjUeCwER/2uTM8AhOOdnuBS/DoN77thgCUyGaWyXzFjyBOjb2HX2yIrKgggAlkwsv2bRjj2p5RajLBnXZAXN3QHlmOmwoDZDyt14jWG7SbFKHApeXKuUMjmcyYS73QsZ/dWaTmXBroZz+YAuHwbhKEuGoj7p/BbYzBuzx6wk9+tCu0JPTDJM70lJUcwqNL4O0vsrCkHT/oxEdZdsknI206/GhNiAvjZJDWRs5v/QgLkTzqETRK5EuDIiOYW8W+KxLT4XS0gcEKV63ICD6ygASiyN0TCVW/NTgR52f9NoSpbZDss5vERQQytGqjFGdavmfMrFGgHQhvac+1/BPxsq1KzWCDASf/Jyd7ku5tI+7qhAV7KDjjkrw6cqtePkIeDC3KHTUnzY9dT70S3jLdeNd4cBlA9cMG6Qw5W7kxTpQ==

EOT
self_link = "https://www.googleapis.com/compute/v1/projects/insbhairava/zones/asia-south1-a/instances/openvpnsvr"
ssh_login = "ssh -i keys/gl_ssh_key.pem ubuntu@35.207.205.217"
vmimage_info = {
  "family" = "ubuntu-minimal-2510-amd64"
  "id" = "projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2510-questing-amd64-v20260517"
  "image_id" = "5632264564174291128"
  "name" = "ubuntu-minimal-2510-questing-amd64-v20260517"
  "project" = "ubuntu-os-cloud"
  "self_link" = "https://www.googleapis.com/compute/v1/projects/ubuntu-os-cloud/global/images/ubuntu-minimal-2510-questing-amd64-v20260517"
  "status" = "READY"
}
```

+ `OpenVPN` configuration file will be under `./ovpn/ubuntu.ovpn`.
+ `ssh` keys will be under `./keys/gl_ssh_key.pem` and `./keys/gl_ssh_key.pub`.

## Connect to Remote VM
Once infrastructure is provisioned, we can connect to the remote instance using the `ssh` keys as below:
```bash
# Grab the SSH Command
λ terraform output -raw ssh_login

# output
# ssh -i keys/gl_ssh_key.pem ubuntu@35.207.205.217

# Connect
λ ssh -i keys/gl_ssh_key.pem ubuntu@35.207.205.217
The authenticity of host '35.207.205.217 (35.207.205.217)' can't be established.
ED25519 key fingerprint is: SHA256:nZpuqlhUBnsH6VyUajvrMRXyoQZS8HUOlOJezHRklGo
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '35.207.205.217' (ED25519) to the list of known hosts.
Welcome to Ubuntu 25.10 (GNU/Linux 6.17.0-1016-gcp x86_64)

 * Documentation:  https://docs.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

This system has been minimized by removing packages and content that are
not required on a system that users do not log into.

To restore this content, you can run the 'unminimize' command.

1 update can be applied immediately.
1 of these updates is a standard security update.
To see these additional updates run: apt list --upgradable

New release '26.04 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

Last login: Wed May 20 17:36:00 2026 from 107.135.56.177
-bash: warning: setlocale: LC_ALL: cannot change locale (en_US.UTF-8): No such file or directory
ubuntu@openvpnsvr:~$
```

## Download OpenVPN client
Download the official client application that enables you to securely access your private network resources or region from the link [OpenVPN Client](https://openvpn.net/client/).

Once installed, open the client and load the configuration file `./ovpn/ubuntu.ovpn` to connect to the appropriate region.

Once connected, check the region details as below which should show the relevant region:

```bash
λ curl ipinfo.io
{
  "ip": "35.207.205.217",
  "hostname": "217.205.207.35.bc.googleusercontent.com",
  "city": "Mumbai",
  "region": "Maharashtra",
  "country": "IN",
  "loc": "19.0728,72.8826",
  "org": "AS19527 Google LLC",
  "postal": "400017",
  "timezone": "Asia/Kolkata",
  "readme": "https://ipinfo.io/missingauth"
}
```