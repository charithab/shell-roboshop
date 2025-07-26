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

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
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
    echo -e "Roboshop user is already created ... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app &>>$LOG_FILE
VALIDATE $? "Creating App Directory"

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading user"

rm -rf /app/*
VALIDATE $? "Removing App content"

cd /app  
unzip /tmp/user.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping user"

npm install  &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/user.service /etc/systemd/system/user.service  &>>$LOG_FILE
VALIDATE $? "Creating user.service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon reload"

systemctl enable user  &>>$LOG_FILE
systemctl start user &>>$LOG_FILE
VALIDATE $? "Start user"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $N Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
