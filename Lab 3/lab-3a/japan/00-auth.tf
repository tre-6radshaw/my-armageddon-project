# Provider & Version
# https://registry.terraform.io/providers/hashicorp/aws/6.17.0/docs

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"
}

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
      # configuration_aliases = [ aws.useast1 ]
    }
  }
}

terraform {
  backend "s3" {
    bucket = "japan-medical-s3-backend-435830281557"
    key    = "edo/ap-northeast1/terraform.tfstate"
    region = "ap-northeast-1"
  }
}