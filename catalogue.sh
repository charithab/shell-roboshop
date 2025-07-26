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

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "Disabling Default nodeJs"

dnf module enable nodejs:20 -y  &>>$LOG_FILE
VALIDATE $? "Enabling nodeJs:20"

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "Installing nodeJs:20"

id roboshop
if [ $? -ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>$LOG_FILE
    VALIDATE $? "Creating Roboshop system user"
else
    echo "Roboshop user is already created ... $Y SKIPPING $N"
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App Directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading catalogue"

rm -rf /app/*
VALIDATE $? "Removing App content"

cd /app  
unzip /tmp/catalogue.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping catalogue"

npm install  &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service  &>>$LOG_FILE
VALIDATE $? "Creating catalogue service"

systemctl daemon-reload
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue  &>>$LOG_FILE
VALIDATE $? "Starting catalogue service"

cp $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo  &>>$LOG_FILE
VALIDATE $? "mongo.repo creating"

dnf install mongodb-mongosh -y  &>>$LOG_FILE
VALIDATE $? "Installing mongosh client"

STATUS=$(mongosh --host mongodb.charitha.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt 0 ]
then
    mongosh --host mongodb.charitha.site </app/db/master-data.js  &>>$LOG_FILE
    VALIDATE $? "Mongodb Data loading"
else
    echo -e "Data is already loaded.... $Y SKIPPING $N"
fi
