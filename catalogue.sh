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

#### NodeJS Installation ####
dnf remove nodejs -y &>> ${log_file}
validate $? "Disabling Nodejs Module"

dnf module enable nodejs:20 -y &>> ${log_file}
validate $? "Enabling Nodejs 20 Module"

dnf install nodejs -y &>> ${log_file}
validate $? "Installing Nodejs"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
validate $? "Adding system user"

mkdir /app 
validate $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>> ${log_file}
validate $? "Downloading Catalogue App Content"

cd /app 
validate $? "Changing Directory to /app"
unzip /tmp/catalogue.zip &>> ${log_file}
validate $? "Extracting Catalogue App Content"
npm install &>> ${log_file}
validate $? "Installing Nodejs Dependencies"    
cp catalogue.service /etc/systemd/system/catalogue.service &>> ${log_file}
validate $? "Copy systemctl service file"
systemctl daemon-reload &>> ${log_file}
validate $? "Reloading systemctl daemon"
systemctl enable catalogue &>> ${log_file}
validate $? "Enabling catalogue service"
systemctl start catalogue &>> ${log_file}
validate $? "Starting catalogue service"

cp mongo.repo /etc/yum.repos.d/mongo.repo &>> ${log_file}
validate $? "Adding Mongodb Repo"
dnf install mongodb-mongosh -y &>> ${log_file}
validate $? "Installing Mongodb Client"

mongosh --host $mongodb_host </app/db/master-data.js &>> ${log_file}
validate $? "Loading Catalogue Data" 

systemctl restart catalogue &>> ${log_file}
validate $? "Restarting catalogue service"