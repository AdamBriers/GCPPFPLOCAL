# Terragrunt will copy the Terraform configurations specified by the source parameter, along with any files in the
# working directory, into a temporary folder, and execute your Terraform commands in that folder.
#locals {
#}

terraform {
  source = "../../../modules//gcp_cloud_dns/"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders("org.hcl")
}

dependency "vpc_host_project" {
  config_path = "../vpc_host_project"
}

dependency "vpc_shared_prd" {
  config_path = "../vpc_shared_prd"
}
dependency "vpc_shared_dev" {
  config_path = "../vpc_shared_dev"
}
dependency "vpc_shared_edge" {
  config_path = "../vpc_shared_edge"
}
dependency "vpc_shared_rnd" {
  config_path = "../vpc_shared_rnd"
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  name                               = "private-google-apis-dns"
  project_id                         = dependency.vpc_host_project.outputs.project_id
  private_visibility_config_networks = [
    "${dependency.vpc_shared_prd.outputs.network_self_link}", 
    "${dependency.vpc_shared_dev.outputs.network_self_link}", 
    "${dependency.vpc_shared_edge.outputs.network_self_link}", 
    "${dependency.vpc_shared_rnd.outputs.network_self_link}"
    ]
  description                        = "DNS Zone to ensure access to googleapis.com via the 'Private Network Access' IPs"
  dns_name                           = "googleapis.com."
  description                        = "Private DNS zone for googleapis.com"
  recordsets = [
    {
      name    = "restricted"
      type    = "A"
      ttl     = 300
      records = ["199.36.153.4", "199.36.153.5", "199.36.153.6", "199.36.153.7"]
    },
    {
      name    = "*"
      type    = "CNAME"
      ttl     = 300
      records = ["restricted.googleapis.com."]
    }
  ]
}