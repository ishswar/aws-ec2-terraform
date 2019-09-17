##################################################################################
# OUTPUT
##################################################################################

output "aws_elb_public_dns" {
  value = "${aws_elb.web.dns_name}"
}

output "vpc_id" {
  value = "${aws_vpc.w10_terraform.id}"
}
output "ec2_nginex1" {
  value = aws_instance.nginx.*.id[0]
}

output "ec2_nginex2" {
  value = aws_instance.nginx.*.id[1]
}

output "ec2_instances" {
  value = aws_instance.nginx.*.id
}