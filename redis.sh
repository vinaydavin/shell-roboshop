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
    echo -e "$2 installation ${red}FAILED${reset}" | tee -a ${log_file}
    exit 1
  else
    echo -e "${green}$2 .....${reset}" | tee -a ${log_file}
  fi
}

dnf module disable redis -y &>> ${log_file}
validate $? "Disabling Old Redis Module"
dnf module enable redis:7 -y &>> ${log_file}
validate $? "Enabling Redis 7 Module"
dnf install redis -y &>> ${log_file}
validate $? "Installing Redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c proteted-mode no' /etc/redis/redis.conf &>> ${log_file}
validate $? "Updating Redis Configuration"  
systemctl enable redis &>> ${log_file}
validate $? "Enabling Redis Service"
systemctl start redis &>> ${log_file}
validate $? "Starting Redis Service"

end_time=$(date +%s)
total_time=$(($end_time - $start_time))
echo -e "${green}Total time taken to install Redis: ${total_time} seconds${reset}" | tee -a ${log_file}