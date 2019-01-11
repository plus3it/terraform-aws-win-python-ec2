# Non-Default Python EC2 instance

Configuration in this directory creates an EC2 instance installed with Python 2.7.15 and Git with `python_version`, `aws_region`,`az_to_find_subnet`, `windows_version`, and `name_prefix` set to non-default values.

This example outputs `ami_id`, `ami_name`, `aws_region`, `instance_id`, `key_pair_name`, `public_dns`, `public_ip`, `security_group_id`, `subnet_id`, `vpc_id`, and `vpc_security_group_id`.


## Usage

To run this example you need to execute:

```console
$ terraform init
$ terraform apply
```

The randomly generated administrator password for the EC2 instance is not displayed by default. To get the password, for logging in with Microsoft Remote Desktop (RDP), use this command:

```console
$ terraform output win_pass
r4,PxIOp1n9DW(7!
```

This example creates resources which cost money. When you don't need these resources, destroy them:

```console
$ terraform destroy
```
