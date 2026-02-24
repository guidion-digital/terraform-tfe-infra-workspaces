terraform {
  required_version = ">= 1.6"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0, < 7.0"
    }

    github = {
      source  = "integrations/github"
      version = "6.0.0"
    }

    tfe = {
      source  = "hashicorp/tfe"
      version = "0.58.1"
    }
  }
}
