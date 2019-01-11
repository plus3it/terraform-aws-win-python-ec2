module "ec2_with_python_and_git" {
  source = "../../"

  python_version = "2.7.15"
  aws_region = "us-west-2"
  az_to_find_subnet = "us-west-2a"
  windows_version = "2012"
  name_prefix = "solig"
}
