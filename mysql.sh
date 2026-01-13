#! /bin/bash
userid=$(id -u)
script_dir=$PWD
red="\e[31m"
green="\e[32m"
yellow="\e[33m"
reset="\e[0m"

logs_dir="/var/log/shell-script"
mkdir -p ${logs_dir}
start_time=$(date +%s)
script_name=$(basename "$0" .sh)
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
    echo -e "${green}$2 .....${reset}" | tee -a ${log_file}
  fi
}

dnf install mysql-server -y &>> ${log_file}
validate $? "Installing MySQL"

systemctl enable mysqld &>> ${log_file}
validate $? "Enabling MySQL Service"

systemctl start mysqld &>> ${log_file}
validate $? "Starting MySQL Service"

mysql_secure_installation --set-root-pass RoboShop@1 &>> ${log_file}
validate $? "Setting MySQL Root Password"   

end_time=$(date +%s)
total_time=$(($end_time - $start_time))
echo -e "${green}Total time taken to install Redis: ${total_time} seconds${reset}" | tee -a ${log_file}