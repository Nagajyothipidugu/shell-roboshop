#!/bin/bash 
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m" 
 
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
SCRIPT_DIR=$PWD


mkdir -p $LOGS_FOLDER 
echo "script started executing at :: $(date)" |tee -a $LOG_FILE  
#Check user has root access or not
if [ $USERID -ne 0 ]
then 
   echo -e "$R ERROR:: Please run this script with root access $N" |tee -a $LOG_FILE
   exit 1 # give other than 0 upto 127
else 
   echo -e "$G You are running with root access  $N" |tee -a $LOG_FILE
fi  

VALIDATE(){
    if [ $1 -eq 0 ] 
    then 
     echo -e " $G $2 success... $N" | tee -a $LOG_FILE
    else 
     echo -e " $R $2 failure $N"  | tee -a $LOG_FILE
     exit 1

    fi
    } 

dnf module disable nodejs -y  &>>$LOG_FILE
VALIDATE $? "disabling nodejs " 

dnf module enable nodejs:20 -y &>>$LOG_FILE
VALIDATE $? "enabling nodejs "

dnf install nodejs -y  &>>$LOG_FILE
VALIDATE $? "Installing nodejs " 

id roboshop 
if [ $? -ne 0 ]
then    
  useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop  &>>$LOG_FILE
  VALIDATE $? "Creating system user for roboshop" 
else 
   echo -e "$Y System user roboshop is already created ..SKIPIING  $N" 
fi     

mkdir  -p /app 
VALIDATE $? "Creating app directory"

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the catalogue code"


rm -rf /app/*
cd /app 
unzip /tmp/catalogue.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping the code" 

cd /app 
npm install  &>>$LOG_FILE
VALIDATE $? "installing dependecies" 

cp $SCRIPT_DIR/catalogue.service  /etc/systemd/system/catalogue.service 
VALIDATE $? "copying catalogue service" 

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue 
VALIDATE $? "starting catalogue" 

cp $SCRIPT_DIR/mongo.repo  /etc/yum.repos.d/mongo.repo 
dnf install mongodb-mongosh -y &>>$LOG_FILE
VALIDATE $? "Installing monodb" 

STATUS=$(mongosh --host mongodb.daws84s.site --eval 'db.getMongo().getDBNames().indexOf("catalogue")')
if [ $STATUS -lt  0 ]
then
  mongosh --host mongodb.devaws46.online < /app/db/master-data.js  &>>$LOG_FILE
  VALIDATE $? "Loading data into mongodb" 
else 
  echo -e " $Y Data is already loaded.... SKIPPING $N " 
fi    



