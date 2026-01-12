#! /bin/bash

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
