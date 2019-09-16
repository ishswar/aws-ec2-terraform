#!/usr/bin/env bash

echo "############## About to run terraform destroy #######################"

TERRAFORM_VARS=~/DevOps/AWS/ubuntuvm/terraform.tfvars

terraform destroy -var-file=$TERRAFORM_VARS --force

if [ $? -ne 0 ]; then
  exit
fi
echo "############## About to run terraform apply #######################"

terraform apply -var-file=$TERRAFORM_VARS -auto-approve

terraf_retValue=$?

if [ $terraf_retValue -eq 0 ]; then

export ELB_ADDRESS=$(terraform output -json | jq -r '.aws_elb_public_dns.value')
export EC2_INSTANCE_ID1=$(terraform output -json | jq -r '.ec2_nginex1.value')
export EC2_INSTANCE_ID2=$(terraform output -json | jq -r '.ec2_nginex2.value')

echo "ELB URL is : $ELB_ADDRESS"
echo "EC2 Instance ID1 is : $EC2_INSTANCE_ID1"
echo "EC2 Instance ID2 is : $EC2_INSTANCE_ID2"

export EC2_INSTANCE1_FOUND_IN_OUTPUT=false
export EC2_INSTANCE2_FOUND_IN_OUTPUT=false

echo "About to check on ELB uRL http://$ELB_ADDRESS"

curl -s --head -i http://"$ELB_ADDRESS"
export reValue=$?

echo "About to check if ELB is running "
while [ $reValue -ne 0 ]; do
   sleep 10
   date
   echo "Checking if ELB is running ..."
   curl --head -i http://"$ELB_ADDRESS"
   export reValue=$?
done

echo "ELB seems to be up - now we will try to hit it and get values "


while [ "$EC2_INSTANCE1_FOUND_IN_OUTPUT" = false ] || [ "$EC2_INSTANCE2_FOUND_IN_OUTPUT" = false ]; do

  echo "Geeting index page from ELB [http://$ELB_ADDRESS] and see if it has one of our instance ID .."
  if [ "$EC2_INSTANCE1_FOUND_IN_OUTPUT" = "false" ]; then
     outp=$(curl -s  -i http://"$ELB_ADDRESS" | grep -c "$EC2_INSTANCE_ID1")
     if [ "$outp" -eq 1 ]; then
       EC2_INSTANCE1_FOUND_IN_OUTPUT=true
       echo "Found Instance 1 (ID : $EC2_INSTANCE_ID1) in HTTP Reply"
     fi
  fi

    if [ "$EC2_INSTANCE2_FOUND_IN_OUTPUT" = "false" ]; then
     outp2=$(curl -s  -i http://"$ELB_ADDRESS" | grep -c "$EC2_INSTANCE_ID2")
     if [ "$outp2" -eq 1 ]; then
       EC2_INSTANCE2_FOUND_IN_OUTPUT=true
       echo "Found Instance 2 (ID : $EC2_INSTANCE_ID2) in HTTP Reply"
     fi
  fi

  sleep 10

done

echo "################# END of our test  #################################"

else
  echo "Looks like terraform failed to run not running post terra form tests "
fi
