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

dnf install -y erlang &>> ${log_file}
validate $? "Installing Erlang"
curl -s https://packagecloud.io/install/repositories/rabbitmq/rabbitmq-server/script.rpm.sh | bash &>> ${log_file}
validate $? "Adding RabbitMQ Repo"
dnf install rabbitmq-server -y &>> ${log_file}
validate $? "Installing RabbitMQ"
systemctl enable rabbitmq-server &>> ${log_file}
validate $? "Enabling RabbitMQ Service" 
systemctl start rabbitmq-server &>> ${log_file}
validate $? "Starting RabbitMQ Service"

rabbitmqctl add_user roboshop roboshop123 &>> ${log_file}
validate $? "Adding RabbitMQ User"
rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> ${log_file}
validate $? "Setting RabbitMQ User Permissions"

cp $script_dir/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>> ${log_file}
end_time=$(date +%s)
total_time=$(($end_time - $start_time))
echo -e "${green}Total time taken to install RabbitMQ: ${total_time} seconds${reset}" | tee -a ${log_file}