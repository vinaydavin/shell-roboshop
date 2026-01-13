#!/bin/bash

userid=$(id -u)

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

logs_dir="/var/log/shell-script"
mkdir -p ${logs_dir}

script_name=$(basename "$0" .sh)
log_file="${logs_dir}/${script_name}.log"

echo "Script started at: $(date)" | tee -a ${log_file}

if [ $userid -ne 0 ]; then
  echo -e "${yellow}You must be root to run this script.${reset}" | tee -a ${log_file}
  exit 1
fi

validate(){
  if [ $1 -ne 0 ]; then
    echo -e "$2 installation ${red}FAILED${reset}" | tee -a ${log_file}
    exit 1
  else
    echo -e "${green}$2 installed successfully${reset}" | tee -a ${log_file}
  fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> ${log_file}
validate $? "Adding Mongo Repo"

dnf install mongodb-org -y &>> ${log_file}
validate $? "INSTALLING MongoDB"

systemctl enable mongod &>> ${log_file}
validate $? "Enabling MongoDB Service"

systemctl start mongod 
validate $? "Starting MongoDB Service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf 
validate $? "Allowing Remote Connections to mongodb"

systemctl restart mongod 
validate $? "Restarting MongoDB Service"  