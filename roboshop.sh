#!/bin/bash

ami_id="ami-07ff62358b87c7116"
sg_id="sg-05ff4bd44c0bc3ba5"
subnet_id="subnet-04d4f1ebfd040d45e"
zone_id="Z08339141ZNV0KWJ5D2UQ"
domain_name="vdavin.online"
key="vdavin-pem"


for instance in $@
do
    inst_id=$(aws ec2 run-instances --image-id $ami_id --instance-type t3.micro --subnet-id $subnet_id --security-group-ids $sg_id --key-name $key --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $inst_id --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
    rec_name="$instance.$domain_name"
else
    IP=$(aws ec2 describe-instances --instance-ids $inst_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    rec_name="$domain_name"
fi

echo "$instance: $IP"

aws route53 change-resource-record-sets \
--hosted-zone-id "$zone_id" \
--change-batch "{
  \"Comment\": \"Updating record set\",
  \"Changes\": [{
    \"Action\": \"UPSERT\",
    \"ResourceRecordSet\": {
      \"Name\": \"$rec_name\",
      \"Type\": \"A\",
      \"TTL\": 1,
      \"ResourceRecords\": [{
        \"Value\": \"$IP\"
      }]
    }
  }]
}"
done


pub_ip=$(aws ec2 describe-instances --instance-ids $inst_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
    rec_name="$domain_name"

echo "ssh -i "vdavin-pem.pem" ec2-user@${pub_ip}.compute-1.amazonaws.com"