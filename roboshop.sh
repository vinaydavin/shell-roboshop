#!/bin/bash

ami_id="ami-07ff62358b87c7116"
sg_id="sg-05ff4bd44c0bc3ba5"
subnet_id="subnet-04d4f1ebfd040d45e"

for instance in $@
do
    inst_id=$(aws ec2 run-instances --image-id ami-07ff62358b87c7116 --instance-type t3.micro --subnet-id subnet-04d4f1ebfd040d45e --security-group-ids sg-05ff4bd44c0bc3ba5 --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$instance}]" --query 'Instances[0].InstanceId' --output text)
if [ $instance != "frontend" ]; then
    IP=$(aws ec2 describe-instances --instance-ids $inst_id --query 'Reservations[0].Instances[0].PublicIpAddress' --output text)
else
    IP=$(aws ec2 describe-instances --instance-ids $inst_id --query 'Reservations[0].Instances[0].PrivateIpAddress' --output text)
fi

echo "$instance: $IP"
done
