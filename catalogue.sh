#!/bin/bash

userid=$(id -u)

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

validate(){
  if [ $1 -ne 0 ]; then
    echo -e "$2 ${red}FAILED${reset}" | tee -a ${log_file}
    exit 1
  else
    echo -e "${green}$2 ...${reset}" | tee -a ${log_file}
  fi
}

#### NodeJS Installation ####
dnf remove nodejs -y &>> ${log_file}
validate $? "Disabling Nodejs Module"

curl -fsSL https://rpm.nodesource.com/setup_20.x &>> ${log_file}
validate $? "Enabling Nodejs 20 Module"

dnf install nodejs -y &>> ${log_file}
validate $? "Installing Nodejs"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> ${log_file}
else
    echo -e "${yellow}roboshop user already exists. Skipping user creation step.${reset}" | tee -a ${log_file}
fi
mkdir -p /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> ${log_file}
validate $? "Downloading Catalogue App Content"

cd /app 
rm -rf /app/* &>> ${log_file}
validate $? "Cleaning /app Directory"

unzip /tmp/catalogue.zip &>> ${log_file}

npm install &>> ${log_file}
   
cp $script_dir/catalogue.service /etc/systemd/system/catalogue.service &>> ${log_file}
validate $? "Copy systemctl service file"
systemctl daemon-reload &>> ${log_file}
validate $? "Reloading systemctl daemon"
systemctl enable catalogue &>> ${log_file}
validate $? "Enabling catalogue service"
systemctl start catalogue &>> ${log_file}
validate $? "Starting catalogue service"

cp $script_dir/mongo.repo /etc/yum.repos.d/mongo.repo &>> ${log_file}
validate $? "Adding Mongodb Repo"
dnf install mongodb-mongosh -y &>> ${log_file}
validate $? "Installing Mongodb Client"

mongosh --host $mongodb_host </app/db/master-data.js &>> ${log_file}
validate $? "Loading Catalogue Data" 

systemctl restart catalogue &>> ${log_file}
validate $? "Restarting catalogue service"