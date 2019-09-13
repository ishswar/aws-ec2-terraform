
data "aws_availability_zones" "available" {}

##################################################################################
# PROVIDERS
##################################################################################

provider "aws" {
  access_key = var.aws_access_key
  secret_key = "${var.aws_secret_key}"
  region     = var.aws_region
}

##################################################################################
# RESOURCES
##################################################################################

resource "aws_vpc" "w10-terraform" {
  cidr_block = "10.0.0.0/16"

    tags = {
    Name = "${var.environment_tag}-vpc"
    Environment = var.environment_tag
  }

}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.w10-terraform.id}"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "default" {
  name        = "terraform_example"
  description = "Used in the terraform"


  # SSH access from anywhere
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP access from the VPC
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.environment_tag}-sg"
    Environment = var.environment_tag
  }
}

resource "aws_instance" "nginx" {
  ami           = "ami-0b37e9efc396e4c38" # Ubuntu 16
  instance_type = "t2.micro"
  key_name        = "${var.key_name}"
  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = ["${aws_security_group.default.id}"]

    ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 2
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = "${file(var.private_key_path)}"
    timeout = "2m"
    agent = false
    host = aws_instance.nginx.public_dns
  }

   provisioner "file" {
    source      = "mapEBStoDriver.sh"
    destination = "/tmp/mapEBStoDriver.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
      "lsblk"
    ]
  }

    provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mapEBStoDriver.sh",
      "/tmp/mapEBStoDriver.sh /dev/xvdg"
    ]
  }

  tags = {
    Name = "${var.environment_tag}-ec2-instance"
    Environment = var.environment_tag
  }
}

##################################################################################
# OUTPUT
##################################################################################

output "aws_instance_public_dns" {
    value = "${aws_instance.nginx.public_dns}"
}

output "vpc_id" {
   value = "${aws_vpc.w10-terraform.id}"
}
