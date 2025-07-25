#!/bin/bash

USERID=$(id -u)
R='\e[31m'
G='\e[32m'
Y='\e[33m'
N='\e[0m'
SCRIPT_NAME=$(echo $0 | cut -d "." -f1)
LOGS_FOLDER='/var/log/roboshop-logs'
LOG_FILE=$LOGS_FOLDER/$SCRIPT_NAME.log
SCRIPT_DIR=$PWD

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

dnf module disable nginx -y  &>>$LOG_FILE
VALIDATE $? "Disabling Default Nginx"

dnf module enable nginx:1.24 -y  &>>$LOG_FILE
VALIDATE $? "Enabling Nginx:1.24"

dnf install nginx -y  &>>$LOG_FILE
VALIDATE $? "Installing Nginx:1.24"

systemctl enable nginx  &>>$LOG_FILE
systemctl start nginx   &>>$LOG_FILE
VALIDATE $? "Starting nginx service"

rm -rf /usr/share/nginx/html/*  &>>$LOG_FILE
VALIDATE $? "Removing default HTML content"

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading frontend"

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping frontend"

rm -rf /etc/nginx/nginx.conf
cp $SCRIPT_DIR/nginx.conf /etc/nginx/nginx.conf  &>>$LOG_FILE
VALIDATE $? "creating nginx.conf"

systemctl restart nginx  &>>$LOG_FILE
VALIDATE $? "Restarting nginx"