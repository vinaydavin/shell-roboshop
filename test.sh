#! /bin/bash
a=$1

  echo "aws ec2 describe-instances \
--filters "Name=private-ip-address,Values=$1" \
--query "Reservations[].Instances[].InstanceId" \
--output text
"
