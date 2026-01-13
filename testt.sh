#!/bin/bash

userid=$(id -u)
set -euo pipefail

trap 'echo "Error occurred at line $LINENO while executing command: $BASH_COMMAND"' ERR

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

mongodb_host=$mongodb.vdavin.online
logs_dir="/var/log/shell-script"
mkdir -p ${logs_dir}

script_name=$(basename "$0" .sh)
script_dir=$PWD
log_file="${logs_dir}/${script_name}.log"

echo "Script started at: $(date)" | tee -a ${log_file}

if [ $userid -ne 0 ]; then
  echo -e "${yellow}You must be root to run this script.${reset}" | tee -a ${log_file}
  exit 1
fi


#### NodeJS Installation ####
dnf remove nodejs -y &>> ${log_file}


curl -fsSL https://rpm.nodesource.com/setup_20.x &>> ${log_file}


dnf install nodejs -y &>> ${log_file}


id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> ${log_file}
else
    echo -e "${yellow}roboshop user already exists. Skipping user creation step.${reset}" | tee -a ${log_file}
fi
mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> ${log_file}


cd /app 
rm -rf /app/* &>> ${log_file}


unzip /tmp/catalogue.zip &>> ${log_file}

npm install &>> ${log_file}
   
cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service &>> ${log_file}

systemctl daemon-reload &>> ${log_file}

systemctl enable catalogue &>> ${log_file}

systemctl start catalogue &>> ${log_file}


cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo &>> ${log_file}

dnf install mongodb-mongosh -y &>> ${log_file}


INDEX=$(mongosh mongodb.vdavin.online --quiet --eval "db.getMongo().getDBName().indexOf('catalogue')" &>> ${log_file})
if [ $INDEX -le 0 ]; then
mongosh --host mongodb.vdavin.online </app/db/master-data.js &>> ${log_file}

else
    echo -e "${yellow}Catalogue Data already present. Skipping Catalogue Data Load.${reset}" | tee -a ${log_file}
fi  

systemctl restart catalogue &>> ${log_file}
