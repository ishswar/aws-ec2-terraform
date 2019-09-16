##################################################################################
# VARIABLES
##################################################################################


variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {
  default = "pshah2019v2"
}

variable "instance_count" {
  default = 2
}

variable "environment_tag" {
  default = "uc-w10"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}
/*
To be used by VPC
*/
variable "network_address_space" {
  default = "10.1.0.0/16"
}
variable "subnet1_address_space" {
  default = "10.1.0.0/24"
}
variable "subnet2_address_space" {
  default = "10.1.1.0/24"
}