#! /bin/bash
a=$1

  echo "{aws ec2 describe-instances --filters "Name=private-ip-address,Values=$a" --query "Reservations[].Instances
[].{InstanceId:InstanceId,PrivateIP:PrivateIpAddress,PublicIP:PublicIpAddress}" --output table}"
