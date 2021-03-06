# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
#locals {
#}

terraform {
  source = "../../../modules//subnet/"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("org.hcl")
}

dependency "vpc_shared_edge" {
  config_path = "../vpc_shared_edge"

  # Configure mock outputs for the terraform commands that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    network_name = "network-not-created-yet"
  }
}

dependency "vpc_host_project" {
  config_path = "../vpc_host_project"

  # Configure mock outputs for the terraform commands that are returned when there are no outputs available (e.g the
  # module hasn't been applied yet.
  mock_outputs_allowed_terraform_commands = ["plan", "validate"]
  mock_outputs = {
    project_id = "project-not-created-yet"
  }
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {

  vpc_network_name = dependency.vpc_shared_edge.outputs.network_name
  project_id       = dependency.vpc_host_project.outputs.project_id

  subnets = [
    {
      sub_network_name         = "gc-a-snet-edge-0001"
      sub_network_description  = "Sub network 1 for the Edge environments"
      ip_cidr_range            = "172.26.254.0/24" # Usable 254 IP's: 172.26.254.1 - 172.26.254.254
      region                   = "europe-west2"
      private_ip_google_access = true
    }
  ]
}