terraform {
  required_version = ">= 1.0"
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.58"
    }
  }
}

# TFE provider will use TFE_TOKEN environment variable
provider "tfe" {}

# Create or use existing organization (must already exist)
data "tfe_organization" "org" {
  name = var.organization_name
}

# Create a project named "opa"
resource "tfe_project" "opa" {
  organization = data.tfe_organization.org.name
  name         = var.project_name
}

# Create a workspace for testing OPA policies
resource "tfe_workspace" "opa_test" {
  name              = var.workspace_name
  organization      = data.tfe_organization.org.name
  project_id        = tfe_project.opa.id
  description       = "Test workspace for OPA external data policy demonstration"
  terraform_version = var.terraform_version

  tag_names = ["opa", "demo", "external-data"]
}

