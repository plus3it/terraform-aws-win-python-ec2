# Basic Python EC2 instance

Configuration in this directory creates an EC2 instance installed with Python and Git with no set arguments.

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
