# aws-ec2-terraform

# Introduction 

  In this repo - we have a sample terraform project that does this :
  
  **This is AWS Sample ( provider is AWS ) **
  
  -   Query AWS for available Availability zones & Subnet in given VPC
  -   Create a new VPC 
  -   Create two Subnet in above VPC , attaching Route table  
  -   Create Security Group for VPC ( allow 22 from everywhere & 80 only from local traffic )
  -   Create Security Goup for Elastic Load balancer - only allow Port 80 from everwhere 
  -   Create ELB - attach two Subject from above VPC and attach EC2 instances that we are going to create bellow 
  -   Create two EC2 instance (Ubntu 16 - t2.micro ) 
        - Attach VPC Security Group
        - Attach One of the Subnet of above VPC 
        - Attach 2 GB EBS volume 
        - Attach user key to login via SSH in future 
        - Attach 3 provisioner 
          - File - upload Shell script that will mount above EBS volume in machine 
          - remote-exe - install nginx web server , create a index.html on the fly (using Instance ID in HTML body )
          - remote-exe - run above Shell script that does volume mounting . 
  -   Once two E2 instance has been created - run bash script that will make sure ELB is running and two EC2 instances are accesable and were created  
      via this terrafrom script 
      
      