variable "python_version" {
  description = "Desired version of Python"
  default     = "3.7.2"
}

variable "git_for_win_version" {
  description = "Desired version of Git for Windows"
  default     = "2.20.1"
}

variable "aws_region" {
  description = "AWS Region"
  default     = "us-east-1"
}

variable "az_to_find_subnet" {
  description = "Used to find the default subnet (ignored if subnet_id is provided)"
  default     = "us-east-1c"
}

variable "subnet_id" {
  description = "ID of subnet to use (or default if blank)"
  default     = ""
}

variable "windows_version" {
  description = "Version of Windows Server to use (options are 2008, 2012, 2016)"
  default     = "2016"
}

variable "adm_user" {
  description = "User name of the admin account"
  default     = "Administrator"
}

variable "instance_profile" {
  description = "IAM profile used for launching the instance"
  default     = ""
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP"
  default     = "false"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.medium"
}

variable "userdata_log" {
  description = "Where to log results of instance initialization"
  default     = "C:\\Temp\\userdata.log"
}

variable "create_key_files" {
  description = "Whether to create public and private key files in .godsaker/"
  default     = "true"
}

variable "name_prefix" {
  description = "Prefix used in naming and tagging resources"
  default     = "godsaker"
}

variable "pypi_url" {
  description = "PyPI URL to use for downloading Python packages"
  default     = "https://pypi.org/simple"
}

variable "download_dir" {
  description = "Directory on EC2 instance for downloading binaries"
  default     = "C:\\Users\\Administrator\\Downloads"
}

variable "temp_dir" {
  description = "Directory on EC2 instance for temporary files"
  default     = "C:\\Temp"
}
