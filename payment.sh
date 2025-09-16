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


# validate functions takes input as exit status, what command they tried to install
VALIDATE(){
    if [ $1 -eq 0 ]
    then
        echo -e "$2 is ... $G SUCCESS $N" | tee -a $LOG_FILE
    else
        echo -e "$2 is ... $R FAILURE $N" | tee -a $LOG_FILE
        exit 1
    fi
}

dnf install python3 gcc python3-devel -y &>>$LOG_FILE
VALIDATE $? "Installing python " 

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

curl -o /tmp/payment.zip https://roboshop-artifacts.s3.amazonaws.com/payment-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading the payment code"

rm -rf /app/*
cd /app 
unzip /tmp/payment.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping the code" 

cd /app 
pip3 install -r requirements.txt  &>>$LOG_FILE
VALIDATE $? "installing dependecies" 


cp $SCRIPT_DIR/payment.service  /etc/systemd/system/payment.service 
VALIDATE $? "copying payment service" 

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloading"
systemctl enable payment  &>>$LOG_FILE
VALIDATE $? "Enabling payment"
systemctl start payment &>>$LOG_FILE
VALIDATE $? "Start payment" 

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))

echo -e "Script execution completed successfully..$Y total time-taken $TOTAL_TIME:seconds $N " | tee -a $LOG_FILE

