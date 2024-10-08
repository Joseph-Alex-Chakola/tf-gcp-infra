variable "gcp_svc_key" {

}
variable "gcp_project" {

}
variable "gcp_region" {

}
variable "gcp_vpc" {
  type = list(
    object({
      name                            = string
      routing_mode                    = string
      subnet_name_1                   = string
      subnet_1_cidr                   = string
      subnet_name_2                   = string
      subnet_2_cidr                   = string
      subnet_1_custom_route           = string
      firewall_name                   = string
      firewall_port                   = list(string)
      firewall_source_range           = list(string)
      vm_name                         = string
      machine_type                    = string
      zone                            = string
      image                           = string
      disk_size                       = number
      disk_type                       = string
      db_instance_name                = string
      db_version                      = string
      db_tier                         = string
      db_disk_type                    = string
      db_disk_size                    = number
      availability_type               = string
      global_address_name             = string
      db_name                         = string
      db_username                     = string
      dns_name                        = string
      dns_zone_name                   = string
      service_account                 = string
      service_account_display_name    = string
      serverless_bucket_name          = string
      serverless_bucket_source        = string
      serverless_function_name        = string
      serverless_function_description = string
      serverless_function_runtime     = string
      serverless_function_entry_point = string
      connector_ip_cidr_range         = string
      cloud_function_service_account  = string
      distribution_policy_zones       = list(string)
      autoscaler_name                 = string
      domain_name                     = string
      api_key                         = string
    })
  )
}
