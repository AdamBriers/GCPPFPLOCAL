# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
#locals {
#}

terraform {
  source = "../../../../../modules//service_account/"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("org.hcl")
}

dependency "project" {
  config_path = "../../"


  # Configure mock outputs for the terraform commands that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    project_id = "project-not-created-yet"
  }
}
inputs = {
  project_id  = dependency.project.outputs.project_id
  account_id  = "gc-t-businessobjects-dev-sa"
  description = "Business Objects Test Service Account"
  members = [
    "user:john.foster@placesforpeople.co.uk"
  ]
}
