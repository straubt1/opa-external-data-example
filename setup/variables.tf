variable "organization_name" {
  description = "HCP Terraform organization name (must already exist)"
  type        = string
}

variable "project_name" {
  description = "Name of the project to create"
  type        = string
  default     = "opa"
}

variable "workspace_name" {
  description = "Name of the workspace to create"
  type        = string
  default     = "opa-external-data-demo"
}

variable "auto_apply" {
  description = "Whether to automatically apply changes"
  type        = bool
  default     = false
}

variable "terraform_version" {
  description = "Terraform version to use in the workspace"
  type        = string
  default     = "~> 1.6"
}
