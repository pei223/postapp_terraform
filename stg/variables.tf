variable "project_name" {
  description = "Project name"
  type        = string
  default     = "postapp"
}

variable "AZ1" {
  type    = string
  default = "ap-northeast-1a"
}
variable "AZ2" {
  type    = string
  default = "ap-northeast-1c"
}
variable "AZ3" {
  type    = string
  default = "ap-northeast-1d"
}

variable "db_master_username" {
  type      = string
  sensitive = true
}

variable "db_master_password" {
  type      = string
  sensitive = true
}

variable "db_user_username" {
  type      = string
  sensitive = true
}

variable "db_user_password" {
  type      = string
  sensitive = true
}
