
data "aws_availability_zones" "available" {}

data "aws_subnet_ids" "sub_ids" {
  depends_on = [aws_subnet.subnet1,aws_subnet.subnet2]
  vpc_id = aws_vpc.w10_terraform.id
}

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

resource "aws_vpc" "w10_terraform" {
  cidr_block = var.network_address_space
  enable_dns_hostnames = "true"

    tags = {
    Name = "${var.environment_tag}-vpc"
    Environment = var.environment_tag
  }

}

resource "aws_internet_gateway" "default" {
  vpc_id = "${aws_vpc.w10_terraform.id}"
}

resource "aws_subnet" "subnet1" {
  cidr_block        = "${var.subnet1_address_space}"
  vpc_id            = "${aws_vpc.w10_terraform.id}"
  map_public_ip_on_launch = "true"
  availability_zone = "${data.aws_availability_zones.available.names[0]}"

}

resource "aws_subnet" "subnet2" {
  cidr_block        = "${var.subnet2_address_space}"
  vpc_id            = "${aws_vpc.w10_terraform.id}"
  map_public_ip_on_launch = "true"
  availability_zone = "${data.aws_availability_zones.available.names[1]}"

}

# ROUTING #
resource "aws_route_table" "rtb" {
  vpc_id = "${aws_vpc.w10_terraform.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.default.id}"
  }
}

resource "aws_route_table_association" "rta-subnet1" {
  subnet_id      = "${aws_subnet.subnet1.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

resource "aws_route_table_association" "rta-subnet2" {
  subnet_id      = "${aws_subnet.subnet2.id}"
  route_table_id = "${aws_route_table.rtb.id}"
}

# Our default security group to access
# the instances over SSH and HTTP
resource "aws_security_group" "nginx-sg" {
  name        = "nginx_sg"
  vpc_id      = "${aws_vpc.w10_terraform.id}"


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
    cidr_blocks = ["${var.network_address_space}"]
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

# SECURITY GROUPS #
resource "aws_security_group" "elb-sg" {
  name        = "nginx_elb_sg"
  vpc_id      = "${aws_vpc.w10_terraform.id}"

  #Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  #allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
    tags = {
    Name = "${var.environment_tag}-elb-sg"
    Environment = var.environment_tag
  }

}

# LOAD BALANCER #
resource "aws_elb" "web" {
  name = "nginx-elb"

  subnets         = [aws_subnet.subnet1.id, aws_subnet.subnet2.id]
  security_groups = [aws_security_group.elb-sg.id]
  instances       = aws_instance.nginx.*.id

  listener {
    instance_port     = 80
    instance_protocol = "http"
    lb_port           = 80
    lb_protocol       = "http"
  }

    tags = {
    Name = "${var.environment_tag}-elb"
    Environment = var.environment_tag
  }
}

//resource "aws_instance" "nginx1" {
//  ami           = "ami-0b37e9efc396e4c38" # Ubuntu 16
//  instance_type = "t2.micro"
//  key_name        = var.key_name
//  # Our Security group to allow HTTP and SSH access
//  vpc_security_group_ids = [aws_security_group.nginx-sg.id]
//  subnet_id     = aws_subnet.subnet1.id
//
//    ebs_block_device {
//    device_name = "/dev/sdg"
//    volume_size = 2
//  }
//
//  connection {
//    type = "ssh"
//    user = "ubuntu"
//    private_key = file(var.private_key_path)
//    timeout = "2m"
//    agent = false
//    host = aws_instance.nginx1.public_dns
//  }
//
//   provisioner "file" {
//    source      = "mapEBStoDriver.sh"
//    destination = "/tmp/mapEBStoDriver.sh"
//  }
//
//  provisioner "remote-exec" {
//    inline = [
//      "sudo apt-get update",
//      "sudo apt-get -y install nginx",
//      "lsblk",
//      "export INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id) && echo '<html><head><title>Server One</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Nginx server on EC2 instance ' $INSTANCE_ID ' </span></span></p></body></html>' | sudo tee /var/www/html/index.nginx-debian.html"
//    ]
//  }
//
//    provisioner "remote-exec" {
//    inline = [
//      "chmod +x /tmp/mapEBStoDriver.sh",
//      "/tmp/mapEBStoDriver.sh /dev/xvdg"
//    ]
//  }
//
//  tags = {
//    Name = "${var.environment_tag}-ec2-instance-1"
//    Environment = var.environment_tag
//  }
//}

resource "aws_instance" "nginx" {
  count = var.instance_count
  ami           = "ami-0b37e9efc396e4c38" # Ubuntu 16
  instance_type = "t2.micro"
  key_name        = var.key_name
  # Our Security group to allow HTTP and SSH access
  vpc_security_group_ids = [aws_security_group.nginx-sg.id]

  subnet_id     = sort(data.aws_subnet_ids.sub_ids.ids)[count.index] #data.aws_subnet_ids.sub_ids.ids[count.index] #join("",["aws_subnet.subnet",count.index+1,".id"])

    ebs_block_device {
    device_name = "/dev/sdg"
    volume_size = 2
  }

  connection {
    type = "ssh"
    user = "ubuntu"
    private_key = file(var.private_key_path)
    timeout = "2m"
    agent = false
    host =  self.public_dns #element(aws_instance.nginx.*.public_dns,count.index) #aws_instance.nginx2.public_dns
  }

  //
   provisioner "file" {
    source      = "./provisioners/mapEBStoDriver.sh"
    destination = "/tmp/mapEBStoDriver.sh"
  }

  /*
  Install Nginx Web server
  In inex.html put EC2 instane ID so we know ELB is working
  In BASH file will also check for this value to see that this server is indeed was created part of this terraform
  */
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get -y install nginx",
      "lsblk",
      "export INSTANCE_ID=$(curl --silent http://169.254.169.254/latest/meta-data/instance-id) && echo '<html><head><title>Server One</title></head><body style=\"background-color:#1F778D\"><p style=\"text-align: center;\"><span style=\"color:#FFFFFF;\"><span style=\"font-size:28px;\">Nginx server on EC2 instance ' $INSTANCE_ID ' </span></span></p></body></html>' | sudo tee /var/www/html/index.nginx-debian.html"
    ]
  }

    provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/mapEBStoDriver.sh",
      "/tmp/mapEBStoDriver.sh /dev/xvdg"
    ]
  }

  tags = {
    Name = join("",[var.environment_tag,"-ec",count.index,"-",count.index]) #"${var.environment_tag}-ec2-instance-2"
    Environment = var.environment_tag
  }
}
