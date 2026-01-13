#!/bin/bash

userid=$(id -u)

red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"
start_time=$(date +%s)
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

dnf install maven -y &>> ${log_file}
validate $? "Installing Maven"

id roboshop
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> ${log_file}
else
    echo -e "${yellow}roboshop user already exists. Skipping user creation step.${reset}" | tee -a ${log_file}
fi
mkdir -p /app 

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip &>> ${log_file}
validate $? "Downloading shipping App Content"

cd /app 
rm -rf /app/* &>> ${log_file}
validate $? "Cleaning /app Directory"

unzip /tmp/shipping.zip &>> ${log_file}
mvn clean package &>> ${log_file}
validate $? "Building shipping App"
mv target/shipping-1.0.jar shipping.jar &>> ${log_file}
validate $? "Renaming shipping Jar File" 
cp $script_dir/shipping.service /etc/systemd/system/shipping.service &>> ${log_file}
systemctl daemon-reload &>> ${log_file}
validate $? "Reloading systemctl daemon"
mvn validate &>> ${log_file}
validate $? "Maven Validate"        
mvn compile &>> ${log_file}
validate $? "Maven Compile"
mvn test &>> ${log_file}
validate $? "Maven Test"
mvn package &>> ${log_file}
validate $? "Maven Package"
systemctl enable shipping &>> ${log_file}
validate $? "Enabling shipping service"
systemctl start shipping &>> ${log_file}
validate $? "Starting shipping service"

dnf install mysql -y &>> ${log_file}
validate $? "Installing Mysql Client"

mysql -h mysql.vdavin.online -uroot -pRoboShop@1 < /app/db/schema.sql &>> ${log_file}
validate $? "Creating Shipping Database Schema"

mysql -h mysql.vdavin.online -uroot -pRoboShop@1 < /app/db/app-user.sql &>> ${log_file}
validate $? "Creating Shipping App User"

mysql -h mysql.vdavin.online -uroot -pRoboShop@1 < /app/db/master-data.sql &>> ${log_file}
validate $? "Loading Shipping Data"

systemctl daemon-reload &>> ${log_file}
validate $? "Reloading systemctl daemon"
systemctl restart shipping &>> ${log_file}
validate $? "Restarting shipping service"

end_time=$(date +%s)
total_time=$(($end_time - $start_time))
echo -e "${green}Total time taken to install shipping: ${total_time} seconds${reset}" | tee -a ${log_file}