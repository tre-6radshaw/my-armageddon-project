# Default provider (already there - keep it)
provider "aws" {
  region = var.aws_region   # should be "sa-east-1"
}

# Your gru alias (already there - keep it)
provider "aws" {
  alias  = "saopaulo"
  region = "sa-east-1"
}

provider "aws" {
  alias  = "ap_northeast_1"
  region = "ap-northeast-1"
}

provider "aws" {
  alias  = "useast1"
  region = "us-east-1"

  # Use the same credentials / profile / assume_role as your default provider
  # Usually you can leave it blank if using the same AWS credentials / env vars
}

terraform {
  required_version = ">= 1.5.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

terraform {
  backend "s3" {
    bucket = "brazil-medical-s3-backend-435830281557"
    key    = "gru/sa-east-1/terraform.tfstate"
    region = "sa-east-1"
  }
}