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

dnf module disable nginx -y  &>>LOG_FILE
VALIDATE $? "Disabling nginx " 

dnf module enable nginx:1.24 -y &>>LOG_FILE
VALIDATE $? "Enabling nginx" 

dnf install nginx -y  &>>LOG_FILE
VALIDATE $? "Installing nginx" 

systemctl enable nginx  &>>LOG_FILE
systemctl start nginx  
VALIDATE $? "starting nginx " 

rm -rf /usr/share/nginx/html/*  &>>LOG_FILE
VALIDATE $? "removing dafault nginx content" 

curl -o /tmp/frontend.zip https://roboshop-artifacts.s3.amazonaws.com/frontend-v3.zip &>>LOG_FILE
VALIDATE $? "downloading the frontend code" 

cd /usr/share/nginx/html 
unzip /tmp/frontend.zip &>>LOG_FILE
VALIDATE $? "unzipping the code" 

rm -rf /etc/nginx/nginx.conf  &>>LOG_FILE
VALIDATE $? "removing default nginx conf "
cp $SCRIPT_DIR/nginx.conf  /etc/nginx/nginx.conf 
VALIDATE $?  "Copying nginx.conf" 

systemctl restart nginx 
VALIDATE $? "restarting nginx" 