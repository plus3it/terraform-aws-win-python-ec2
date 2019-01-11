# Basic Windows Python AWS EC2 Instance

This provides an easy way to spin up a Windows AWS EC2 instance installed with the latest Python version and a random administrator password. 

**NOTE:** Be careful with the administrator password!

Tasks performed include these:

1. Create a Windows 2008, 2012, or 2016 Server (default: 2016) AWS EC2 instance
1. Install Python
1. Create security group that only permits access to the instance from your IP
1. Create a new EC2 Key Pair for creating the instance
1. Create a random administrator password for the instance
1. Output the random password so you can login with Microsoft Remote Desktop

Everything created by this *godsaker* will be placed in an ignored directory called `.godsaker` and can be safely deleted after you destroy the resources.

## Examples

All the resources can be created with this command:

```console
$ terraform apply
```

All the resources can be destroyed with this command:

```console
$ terraform destroy
```

## References

Configuring the AWS provider: https://www.terraform.io/docs/providers/aws/index.html
