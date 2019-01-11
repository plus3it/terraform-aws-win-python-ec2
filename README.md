# AWS EC2 Instance Windows Python module

Terraform module which creates an AWS Windows Server EC2 instance installed with Python and Git.

Without any required input, the module creates everything you need for a quick ephemeral EC2 instance with the latest version of Python and Git installed:

* [EC2 instance](https://www.terraform.io/docs/providers/aws/r/instance.html) using the latest Windows Server [AMI](https://www.terraform.io/docs/providers/aws/d/ami.html)
* [Security group](https://www.terraform.io/docs/providers/aws/r/security_group.html) only allowing access to the EC2 instance from your IP address using Remote Desktop and WinRM
* [Key pair](https://www.terraform.io/docs/providers/aws/r/key_pair.html) for creating the EC2 instance using a freshly generated 4096-bit RSA TLS key
* A random administrator password to use in connecting via Remote Desktop (RDP) to the EC2 instance (see Security below)

## Usage

```hcl
module "ec2_cluster" {
  source                 = ""YakDriver/win-python-ec2/aws""
  version                = "1.0.1"
}
```

## Examples

* [Basic Python EC2 instance](https://github.com/YakDriver/terraform-aws-win-python-ec2/tree/master/examples/basic)
* [Non-Default Python EC2 instance](https://github.com/YakDriver/terraform-aws-win-python-ec2/tree/master/examples/non_default)

## Networking

To place the EC2 instance in a specific subnet, provide the ID in the `subnet_id` variable. Otherwise, the module will put the EC2 instance in the default subnet associated with the availability zone (AZ) provided in the `az_to_find_subnet` variable but not necessary that AZ.

## Security

The module provides these security features:

* Assignment of the a randomly generated 16-character password with at least 2 upper, 2 lower, 2 special, and 2 numeric characters to the EC2 instance administrator account. The password is marked sensitive in Terraform and will be redacted in logs and the initial output from the module. **To see the password**, type `terraform output win_pass`.
* Generation of a fresh 4096-bit RSA key pair just for the instance (the public and private keys are only saved to the `.godsaker/` directory, locally where Terraform is run).
* Creation of a new security group for the EC2 instance only allowing RDP and WinRM access for the IP address where Terraform is run

However, the module may also have vulnerabilities and should only be used for creating ephemeral instances.

## Authors

Module managed by [Plus3 IT](https://github.com/plus3it).

## License

MIT Licensed. See LICENSE for full details.
