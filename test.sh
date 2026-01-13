#! /bin/bash
read $1

  aws ec2 describe-instances --filters "Name=private-ip-address,Values=$1" --query "Reservations[].Instances
[].{InstanceId:InstanceId,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}" --output table
