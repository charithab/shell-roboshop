#!/bin/bash

START_TIME=$(date +%s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"
SCRIPT_NAME=$(echo $0 | cut -d "." f1)
LOGS_FOLDER="/var/log/roboshop-logs"
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD

mkdir -p $LOGS_FOLDER
echo "Script started executing at: $(date)" | tee -a $LOG_FILE

# check the user has root priveleges or not
if [ $USERID -ne 0 ]
then
    echo -e "$R ERROR: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access" | tee -a $LOG_FILE
fi

echo "Please enter rabbitmq password"
read -s RABBITMQ_PASSWORD

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

cp $SCRIPT_DIR/rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo &>>LOG_FILE
VALIDATE $? "Creating rabbitmq repo"

dnf install rabbitmq-server -y  &>>LOG_FILE
VALIDATE $? "Installing rabbitmq server"

systemctl enable rabbitmq-server   &>>LOG_FILE
VALIDATE $? "Enabling rabbitmq server"

systemctl start rabbitmq-server  &>>LOG_FILE
VALIDATE $? "Starting rabbitmq server"

rabbitmqctl add_user roboshop $RABBITMQ_PASSWORD  &>>LOG_FILE
VALIDATE $? "Adding rabbitmq user"

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*"  &>>LOG_FILE
VALIDATE $? "Permission set"


END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $N Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE