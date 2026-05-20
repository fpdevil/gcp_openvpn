# storing state in google cloud storage
# gsutil mb gs://${PROJECT_ID}-tf-state
# gsutil versioning set on gs://${PROJECT_ID}-tf-state
# gcloud services enable iamcredentials.googleapis.com
terraform {
  backend "gcs" {
    bucket = "insbhairava-tf-state"    # ensure this bucket is created
    prefix = "openvpn-project/backend" # this will be automatically added at front
  }
}

