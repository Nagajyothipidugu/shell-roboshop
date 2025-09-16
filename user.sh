#!/bin/bash 
START_TIME=$(date +%s)
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

curl -o /tmp/user.zip https://roboshop-artifacts.s3.amazonaws.com/user-v3.zip &>>$LOG_FILE
VALIDATE $? "Downloading the user code"

rm -rf /app/*
cd /app 
unzip /tmp/user.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping the code" 

cd /app 
npm install  &>>$LOG_FILE
VALIDATE $? "installing dependecies" 

cp $SCRIPT_DIR/user.service  /etc/systemd/system/user.service 
VALIDATE $? "copying user service" 

systemctl daemon-reload &>>$LOG_FILE
systemctl enable catalogue  &>>$LOG_FILE
systemctl start catalogue 
VALIDATE $? "starting user" 

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))

echo -e "Script execution completed successfully..$Y total time-taken $TOTAL_TIME  seconds $N " | tee -a $LOG_FILE
