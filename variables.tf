variable "python_version" {
  default = "3.7.2"
}

variable "git_for_win_version" {
  default = "2.20.1"
}

variable "aws_region" {
  default = "us-east-1"
}

variable "availability_zone" {
  default = "us-east-1c"
}

variable "subnet_id" {
  default = ""
}

variable "windows_version" {
  default = "2016"
}

variable "adm_user" {
  default = "Administrator"
}

variable "instance_profile" {
  default = ""
}

variable "assign_public_ip" {
  default = "false"
}

variable "instance_type" {
  default = "t2.medium"
}

variable "userdata_log" {
  default = "C:\\Temp\\userdata.log"
}
