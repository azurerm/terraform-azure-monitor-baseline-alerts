variable "management_group_name" {
  description = "The name of the management group to which the policies will be assigned."
  type        = string
  default     = "Tenant Root Group"
}

variable "subscription_id" {
  description = "The subscription ID for default provider."
  type        = string
}

variable "path_policies" {
  description = "The folder name of the policies directory."
  type        = string
  default     = "policies"
}

variable "path_initiatives" {
  description = "The folder name of the initiatives directory."
  type        = string
  default     = "initiatives"
}

variable "path_parameters" {
  description = "The folder name of the parameters directory."
  type        = string
  default     = "parameters"
}


variable "initiatives_assignment" {
  description = "Performs the assignment of the initiative to the management group."
  type        = bool
  default     = true  
}

variable "location" {
  type    = string
  default = "northeurope"
}

variable "resource_group_name" {
  type    = string
  default = "rg-mon-prd-ne-001"
}

variable "user_assigned_identity_name" {
  type    = string
  default = "mi-mon-prd-ne-001"
}
