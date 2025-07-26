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

echo "Please enter Shipping password"
read -s SHIPPING_PASSWORD

VALIDATE() {
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install maven -y  &>>LOG_FILE
VALIDATE $? "Installing maven and Java"

id roboshop
if [ $? ne 0 ]
then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>>LOG_FILE
    VALIDATE $? "Roboshop user is created"
else
    echo -e "Roboshop user is already created... $Y SKIPPING $N"  | tee -a $LOG_FILE
fi

mkdir -p /app  &>>LOG_FILE
VALIDATE $? "Creating App Directory"

curl -L -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>LOG_FILE
VALIDATE $? "Downloading shipping"

rm -rf /app/* &>>LOG_FILE
VALIDATE $? "Removing app content"

cd /app 
unzip /tmp/shipping.zip &>>LOG_FILE
VALIDATE $? "Unzipping shipping"

mvn clean package &>>LOG_FILE
VALIDATE $? "Packaging"

mv target/shipping-1.0.jar shipping.jar  &>>LOG_FILE
VALIDATE $? "Renaming and moving the Jar file"

cp $SCRIPT_DIR/shipping.service /etc/systemd/system/shipping.service  &>>LOG_FILE
VALIDATE $? "Creating shipping service"

systemctl enable shipping  &>>LOG_FILE
systemctl start shipping &>>LOG_FILE
VALIDATE $? "Starting shipping"

dnf install mysql -y  &>>LOG_FILE
VALIDATE $? "Installing mysql"

mysql -h mysql.daws84s.site -u root -p$MYSQL_ROOT_PASSWORD -e 'use cities' &>>$LOG_FILE
if [ $? -ne 0 ]
then
    mysql -h mysql.charitha.site -uroot -p$SHIPPING_PASSWORD < /app/db/schema.sql &>>LOG_FILE
    mysql -h mysql.charitha.site -uroot -p$SHIPPING_PASSWORD < /app/db/app-user.sql  &>>LOG_FILE
    mysql -h mysql.charitha.site -uroot -p$SHIPPING_PASSWORD < /app/db/master-data.sql &>>LOG_FILE
    VALIDATE $? "Data is loading into db"
else
    echo -e "Data is already loaded into MYSQL... $Y SKIPPING $N"
fi

systemctl restart shipping &>>LOG_FILE
VALIDATE $? "Restart shipping"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME ))

echo -e "Script execution completed successfully, $N Time taken: $TOTAL_TIME seconds $N" | tee -a $LOG_FILE
