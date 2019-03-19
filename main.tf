provider "aws" {
  region = "${var.aws_region}"
}

# AMIs and AMI keys - data structures to represent, no user input considered... yet
locals {
  windows_versions = ["2008", "2012", "2016"]

  ami_name_filters = {
    "${local.windows_versions[0]}" = "Windows_Server-2008-R2_SP1-English-64Bit-Base*"
    "${local.windows_versions[1]}" = "Windows_Server-2012-R2_RTM-English-64Bit-Base*"
    "${local.windows_versions[2]}" = "Windows_Server-2016-English-Full-Base*"
  }

  # plus3, amazon, and ubuntu canonical
  ami_owners = ["801119661308"]

  ami_virtualization_type = "hvm"
}

# security and networking ===========================

# Subnet for instance
data "aws_subnet" "godsaker" {
  id = "${var.subnet_id == "" ? aws_default_subnet.godsaker.id : var.subnet_id}"
}

# Used to get local ip for security group ingress
data "http" "ip" {
  url = "http://ipv4.icanhazip.com"
}

# used for importing the key pair created using aws cli
resource "aws_key_pair" "auth" {
  key_name   = "${random_id.godsaker.b64_url}-key"
  public_key = "${tls_private_key.gen_key.public_key_openssh}"
}

resource "tls_private_key" "gen_key" {
  count     = "1"
  algorithm = "RSA"
  rsa_bits  = "4096"
}

resource "random_string" "password" {
  count            = 1
  length           = 16
  special          = true
  override_special = "()~!@#^*+=|{}[]:;,?"
  min_lower        = 2
  min_numeric      = 2
  min_special      = 2
  min_upper        = 2
}

resource "random_id" "godsaker" {
  byte_length = 5
  prefix      = "${var.name_prefix}-"
}

resource "aws_default_subnet" "godsaker" {
  availability_zone = "${var.az_to_find_subnet}"
}

# Security group to access the instances over WinRM
resource "aws_security_group" "win_sg" {
  count       = 1
  name        = "${random_id.godsaker.b64_url}"
  description = "Used for godsaker"
  vpc_id      = "${data.aws_subnet.godsaker.vpc_id}"

  tags {
    Name = "${random_id.godsaker.b64_url}"
  }

  # access from anywhere
  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.ip.body)}/32"]
  }

  # access from anywhere
  ingress {
    from_port   = 5985
    to_port     = 5986
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.ip.body)}/32"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ec2 instance ===========================
#used just to find the ami id matching criteria, which is then used in provisioning resource
data "aws_ami" "find_ami" {
  count       = 1
  most_recent = true

  filter {
    name   = "virtualization-type"
    values = ["${local.ami_virtualization_type}"]
  }

  filter {
    name   = "name"
    values = ["${local.ami_name_filters[var.windows_version]}"]
  }

  owners = "${local.ami_owners}"
}

# ec2 instance
resource "aws_instance" "godsaker" {
  count = 1
  ami   = "${data.aws_ami.find_ami.id}"

  associate_public_ip_address = "${var.assign_public_ip}"
  iam_instance_profile        = "${var.instance_profile}"
  instance_type               = "${var.instance_type}"
  key_name                    = "${aws_key_pair.auth.id}"
  subnet_id                   = "${var.subnet_id}"
  user_data                   = "<powershell>\n${data.template_file.userdata.rendered}\n</powershell>"
  vpc_security_group_ids      = ["${aws_security_group.win_sg.id}"]

  tags {
    Name = "${random_id.godsaker.b64_url}"
  }

  timeouts {
    create = "20m"
  }

  connection {
    type     = "winrm"
    user     = "${var.adm_user}"
    password = "${random_string.password.result}"
    timeout  = "10m"
  }

  provisioner "file" {
    content     = "${data.http.verify_instance.body}"
    destination = "C:\\scripts\\python_test.ps1"
  }

  provisioner "remote-exec" {
    inline = [
      "powershell.exe -File C:\\scripts\\python_test.ps1",
    ]
  }

  lifecycle {
    # Due to several known issues in Terraform AWS provider related to arguments of aws_instance:
    # (eg, https://github.com/terraform-providers/terraform-provider-aws/issues/2036)
    # we have to ignore changes in the following arguments
    ignore_changes = ["private_ip", "root_block_device", "ebs_block_device"]
  }
}

data "http" "verify_instance" {
  url = "https://raw.githubusercontent.com/plus3it/terraform-aws-win-python-ec2/master/python_test.ps1"
}

# userdata ===========================
data "http" "userdata" {
  url = "https://raw.githubusercontent.com/plus3it/terraform-aws-win-python-ec2/master/userdata.ps1"
}

data "template_file" "userdata" {
  count    = 1
  template = "${data.http.userdata.body}"

  vars {
    download_dir  = "${var.download_dir}"
    seven_zip_url = "https://www.7-zip.org/a/7z1806-x64.exe"
    git_url       = "https://github.com/git-for-windows/git/releases/download/v${var.git_for_win_version}.windows.1/Git-${var.git_for_win_version}-64-bit.exe"
    pypi_url      = "${var.pypi_url}"
    # https://www.python.org/ftp/python/2.7.15/python-2.7.15.amd64.msi
    python_url    = "https://www.python.org/ftp/python/${var.python_version}/python-${var.python_version}-amd64.exe"
    adm_pass      = "${random_string.password.result}"
    adm_user      = "${var.adm_user}"
    temp_dir      = "${var.temp_dir}"
    userdata_log  = "${var.userdata_log}"
  }
}

# local files for key pairs ================================
resource "local_file" "public" {
  count    = "${var.create_key_files == "true" ? 1 : 0}"
  content  = "${tls_private_key.gen_key.public_key_openssh}"
  filename = ".godsaker/id_rsa_${random_id.godsaker.b64_url}.pub"
}

resource "local_file" "private" {
  count    = "${var.create_key_files == "true" ? 1 : 0}"
  content  = "${tls_private_key.gen_key.private_key_pem}"
  filename = ".godsaker/id_rsa_${random_id.godsaker.b64_url}.pem"
}
