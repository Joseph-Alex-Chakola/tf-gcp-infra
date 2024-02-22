variable "gcp_svc_key" {

}
variable "gcp_project" {

}
variable "gcp_region" {

}
variable "gcp_vpc" {
  type = list(
    object({
      name                  = string
      routing_mode          = string
      subnet_name_1         = string
      subnet_1_cidr         = string
      subnet_name_2         = string
      subnet_2_cidr         = string
      subnet_1_custom_route = string
      firewall_name         = string
      firewall_port         = list(string)
      firewall_source_range = list(string)
      vm_name               = string
      machine_type          = string
      zone                  = string
      image                 = string
      disk_size             = number
      disk_type             = string
    })
  )
}
