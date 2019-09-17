#!/usr/bin/env bash

echo "############## About to run terraform destroy #######################"

TERRAFORM_VARS=~/DevOps/AWS/ubuntuvm/terraform.tfvars

terraform destroy -var-file=$TERRAFORM_VARS --force

if [ $? -ne 0 ]; then
  echo "Terraform destroy did not finish gracfully - further tests will be skiped"
  exit
fi

echo "############## About to run terraform apply #######################"

terraform apply -var-file=$TERRAFORM_VARS -auto-approve

terraf_retValue=$?

if [ $terraf_retValue -eq 0 ]; then

  export ELB_ADDRESS=$(terraform output -json | jq -r '.aws_elb_public_dns.value')
  export EC2_INSTANCE_ID1=$(terraform output -json | jq -r '.ec2_nginex1.value')
  export EC2_INSTANCE_ID2=$(terraform output -json | jq -r '.ec2_nginex2.value')

  if [[ -z "$ELB_ADDRESS" ]]; then
    echo "Unable to get ELB_ADDRESS URL - test will exit" 1>&2
    exit 1
  fi

  if [[ -z "$EC2_INSTANCE_ID1" ]]; then
    echo "Unable to get EC2_INSTANCE_ID1 - test will exit" 1>&2
    exit 1
  fi

  if [[ -z "$EC2_INSTANCE_ID2" ]]; then
    echo "Unable to get EC2_INSTANCE_ID2 - test will exit" 1>&2
    exit 1
  fi

  echo "ELB URL is : $ELB_ADDRESS"
  echo "EC2 Instance ID1 is : $EC2_INSTANCE_ID1"
  echo "EC2 Instance ID2 is : $EC2_INSTANCE_ID2"

  export EC2_INSTANCE1_FOUND_IN_OUTPUT=false
  export EC2_INSTANCE2_FOUND_IN_OUTPUT=false

  echo "About to check on ELB uRL http://$ELB_ADDRESS"

  export reValue=1
  echo "About to check if ELB is running "
  giveUpCount=15
  SECONDS=0
  while [ $reValue -ne 0 ]; do
    sleep 10

    if [ $giveUpCount -eq 15 ]; then
      echo "Checking if ELB is running ..."
    else
      echo "Still checking if ELB isrunning ... [$SECONDS seconds]"
    fi

    curl --head -s -i http://"$ELB_ADDRESS" -o temp.txt
    export reValue=$?

    if [ $reValue -eq 0 ]; then
      http_twoH=$(cat temp.txt | grep -c "200")

      if [ $http_twoH -eq 0 ]; then
        echo "Server responeded non 200 OK code - will try again"
        reValue=1
      fi

      rm temp.txt
    fi

    giveUpCount=$((giveUpCount - 1))

    if [ $giveUpCount -eq 0 ]; then
      echo "Looks like ELB is has not come up after 150 seconds - giving up test"
      exit 1
    fi

  done

  echo "ELB seems to be up - now we will try to hit it and get values "

giveUpCount=15
SECONDS=0
  while [ "$EC2_INSTANCE1_FOUND_IN_OUTPUT" = false ] || [ "$EC2_INSTANCE2_FOUND_IN_OUTPUT" = false ]; do

    if [ $giveUpCount -eq 15 ]; then
    echo "Geeting index page from ELB [http://$ELB_ADDRESS] and see if it has one of our instance ID .."
    else
    echo "Still checking index page from ELB [http://$ELB_ADDRESS] and see if it has one of our instance ID ..[$SECONDS seconds]"
    fi

    if [ "$EC2_INSTANCE1_FOUND_IN_OUTPUT" = "false" ]; then
      outp=$(curl -s -i http://"$ELB_ADDRESS" | grep -c "$EC2_INSTANCE_ID1")
      if [ "$outp" -eq 1 ]; then
        EC2_INSTANCE1_FOUND_IN_OUTPUT=true
        echo "Found Instance 1 (ID : $EC2_INSTANCE_ID1) in HTTP Reply"
      fi
    fi

    if [ "$EC2_INSTANCE2_FOUND_IN_OUTPUT" = "false" ]; then
      outp2=$(curl -s -i http://"$ELB_ADDRESS" | grep -c "$EC2_INSTANCE_ID2")
      if [ "$outp2" -eq 1 ]; then
        EC2_INSTANCE2_FOUND_IN_OUTPUT=true
        echo "Found Instance 2 (ID : $EC2_INSTANCE_ID2) in HTTP Reply"
      fi
    fi

    giveUpCount=$((giveUpCount - 1))

    if [ $giveUpCount -eq 0 ]; then
      echo "Looks like Nginx server is not returning Instance ID as part of index.htm/l body; test will exit"
      exit 1
    fi

    sleep 10

  done

  echo "################# END of our test  #################################"

else
  echo "Looks like terraform failed to run not running post terraform tests "
fi
