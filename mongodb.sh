#!/bin/bash

USERID=$(id -u)
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FOLDER='/var/log/roboshop-logs'
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log

mkdir -p $LOGS_FOLDER
echo "script started executing at: $(date)" | tee -a $LOG_FILE

if [ $USERID -ne 0 ]
then
    echo -e "$R Error: Please run this script with root access $N" | tee -a $LOG_FILE
    exit 1
else
    echo "You are running with root access"
fi

VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is...$G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is...$R FAILURE $N" | tee -a $LOG_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo @>>$LOG_FILE
VALIDATE $? "Creating mongo.repo file"

dnf install mongodb-org -y @>>$LOG_FILE
VALIDATE $? "Installing MongoDB"

systemctl enable mongod @>>$LOG_FILE
VALIDATE $? "Enabling MongoDB"

systemctl start mongod @>>$LOG_FILE
VALIDATE $? "Starting Mongod service"

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf @>>$LOG_FILE
VALIDATE $? "Updated IP address"

systemctl restart mongod @>>$LOG_FILE
VALIDATE $? "Restarted Mongod service"