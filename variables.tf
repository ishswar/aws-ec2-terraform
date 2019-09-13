##################################################################################
# VARIABLES
##################################################################################


variable "aws_access_key" {}
variable "aws_secret_key" {}
variable "private_key_path" {}
variable "key_name" {
  default = "pshah2019v2"
}

variable "environment_tag" {
  default = "uc-w10"
}

variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "us-west-2"
}