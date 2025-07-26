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
    echo -e "User is already created... $Y SKIPPING $N" | tee -a $LOG_FILE
fi

mkdir -p /app  &>>$LOG_FILE
VALIDATE $? "App directory creation"

curl -L -o /tmp/cart.zip https://roboshop-artifacts.s3.amazonaws.com/cart-v3.zip  &>>$LOG_FILE
VALIDATE $? "Cart download"

rm -rf /app/* &>>$LOG_FILE
VALIDATE $? "Removing app content"

cd /app 
unzip /tmp/cart.zip &>>$LOG_FILE
VALIDATE $? "Unzipping cart"

npm install &>>$LOG_FILE
VALIDATE $? "Installing Dependencies"

cp $SCRIPT_DIR/cart.service /etc/systemd/system/cart.service &>>$LOG_FILE
VALIDATE $? "Creating cart.service"

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "Daemon-reload"

systemctl enable cart  &>>$LOG_FILE
VALIDATE $? "Enabling cart"

systemctl start cart &>>$LOG_FILE
VALIDATE $? "Starting cart"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $N Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
