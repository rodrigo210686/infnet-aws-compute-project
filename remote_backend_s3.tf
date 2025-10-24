terraform {
  backend "s3" {
    bucket = "infnet-proj-remote-state-bucket-rodrigo"
    key    = "infnet-project-1/terraform.tfstate"
    region = "us-east-1"
  }
}