output "ami_id" {
  description = "ID of AMI used to launch instance"
  value       = "${module.ec2_with_python_and_git.ami_id}"
}

output "ami_name" {
  description = "Name of AMI used to launch instance"
  value       = "${module.ec2_with_python_and_git.ami_name}"
}

output "win_pass" {
  description = "Randomly generated password assigned to Admin account"
  value       = "${module.ec2_with_python_and_git.win_pass}"
  sensitive   = true
}

output "public_dns" {
  description = "Public DNS name assigned to the instance"
  value       = "${module.ec2_with_python_and_git.public_dns}"
}

output "public_ip" {
  description = "Public IP assigned to the instance"
  value       = "${module.ec2_with_python_and_git.public_ip}"
}

output "instance_id" {
  description = "ID of EC2 instance"
  value       = "${module.ec2_with_python_and_git.instance_id}"
}

output "key_pair_name" {
  description = "Name of the key pair generated for instance"
  value       = "${module.ec2_with_python_and_git.key_pair_name}"
}

output "security_group_id" {
  description = "ID of the security group for the instance"
  value       = "${module.ec2_with_python_and_git.security_group_id}"
}

output "vpc_security_group_id" {
  description = "ID of the VPC security group"
  value       = ["${module.ec2_with_python_and_git.vpc_security_group_id}"]
}

output "subnet_id" {
  description = "ID of the subnet"
  value       = "${module.ec2_with_python_and_git.subnet_id}"
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = "${module.ec2_with_python_and_git.vpc_id}"
}

output "aws_region" {
  description = "Region used by the module"
  value       = "${module.ec2_with_python_and_git.aws_region}"
}
