terraform {
  backend "s3" {
    bucket = "infnet-proj-remote-state-bucket-rodrigo-2"
    key    = "infnet-project-1/terraform.tfstate"
    region = "us-east-1"
  }
}