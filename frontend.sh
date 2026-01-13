#!/bin/bash

userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

logs_dir="/var/log/shell-script"
mkdir -p ${logs_dir}
start_time=$(date +%s)
script_name=$(basename "$0" .sh)
script_dir=$PWD
log_file="${logs_dir}/${script_name}.log"

echo "Script started at: $(date)" | tee -a ${log_file}

if [ $userid -ne 0 ]; then
  echo -e "${Y}You must be root to run this script.${N}" | tee -a ${log_file}
  exit 1
fi

validate(){
  if [ $1 -ne 0 ]; then
    echo -e "$2 ${R}FAILED${N}" | tee -a ${log_file}
    exit 1
  else
    echo -e "${G}$2 ...${N}" | tee -a ${log_file}
  fi
}

dnf module disable nginx -y &>> ${log_file}
validate $? "Disabling Old Nginx Module"
dnf module enable nginx:1.24 -y &>> ${log_file}
validate $? "Enabling Nginx 1.24 Module"
dnf install nginx -y  &>> ${log_file}
validate $? "Installing Nginx"

systemctl enable nginx  &>> ${log_file}
validate $? "Enabling Nginx Service"
systemctl start nginx    &>> ${log_file}
validate $? "Starting Nginx Service"

rm -rf /usr/share/nginx/html/*  &>> ${log_file}
validate $? "Cleaning Nginx HTML Directory"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>> ${log_file}
validate $? "Downloading Frontend Content"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip

cp $script_dir/nginx.conf etc/nginx/nginx.conf &>> ${log_file}

systemctl daemon-reload
telnet catalogue.vdavin.online 8080
systemctl restart nginx 


end_time=$(date +%s)
total_time=$(($end_time - $start_time))
echo -e "${G}Total time taken to install Ris: ${total_time} seconds${N}" | tee -a ${log_file}