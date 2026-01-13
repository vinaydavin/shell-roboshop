#!/bin/bash

userid=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
start_time=$(date +%s)
mongodb_host=$mongodb.vdavin.online
logs_dir="/var/log/shell-script"
mkdir -p ${logs_dir}

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

dnf install python3 gcc python3-devel -yF &>> ${log_file}
validate $? "Installing python"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> ${log_file}
else
    echo -e "${Y}roboshop user already exists. Skipping user creation step.${N}" | tee -a ${log_file}
fi
mkdir -p /app 

curl -L -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip &>> ${log_file}
validate $? "Downloading payment App Content"

cd /app 
rm -rf /app/* &>> ${log_file}
validate $? "Cleaning /app Directory"

unzip /tmp/payment.zip &>> ${log_file}

pip3 install -r requirements.txt &>> ${log_file}
validate $? "Installing payment dependencies" 
cp $script_dir/payment.service /etc/systemd/system/payment.service &>> ${log_file}
systemctl daemon-reload &>> ${log_file}
validate $? "Reloading systemctl daemon"

systemctl enable payment &>> ${log_file}
validate $? "Enabling payment service"
systemctl restart payment &>> ${log_file}
validate $? "Starting payment service"

end_time=$(date +%s)
total_time=$(($end_time - $start_time))
echo -e "${G}Total time taken to install payment: ${total_time} seconds${N}" | tee -a ${log_file}