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

echo "Please enter root password"
read -s MYSQL_ROOT_PASSWORD

VALIDATE(){
    if [ $1 -eq 0 ] 
    then 
      echo -e " $G $2 success... $N" | tee -a $LOG_FILE
    else 
      echo -e " $R $2 failure $N"  | tee -a $LOG_FILE
      exit 1

    fi
    } 

dnf install maven -y  &>>$LOG_FILE
VALIDATE $? "Installing maven " 

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

curl -o /tmp/shipping.zip https://roboshop-artifacts.s3.amazonaws.com/shipping-v3.zip  &>>$LOG_FILE
VALIDATE $? "Downloading the shipping code"

rm -rf /app/*
cd /app 
unzip /tmp/shipping.zip  &>>$LOG_FILE
VALIDATE $? "Unzipping the code" 

cd /app 
mvn clean package  &>>$LOG_FILE
VALIDATE $? "installing dependecies" 
mv target/shipping-1.0.jar shipping.jar &>>$LOG_FILE
VALIDATE $? "Renaming as shipping.jar"

cp $SCRIPT_DIR/shipping.service  /etc/systemd/system/shipping.service 
VALIDATE $? "copying user service" 

systemctl daemon-reload &>>$LOG_FILE
VALIDATE $? "reloading"
systemctl enable shipping  &>>$LOG_FILE
VALIDATE $? "Enabling shipping"
systemctl start shipping &>>$LOG_FILE
VALIDATE "Start shipping" 

dnf install mysql -y  &>>$LOG_FILE
VALIDATE $? "Installing mysql client" 

mysql -h mysql.devaws46.online -uroot -p$MYSQL_ROOT_PASSWORD  -e 'use cities'
if [ $? -ne 0 ]
then 
     mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/schema.sql &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/app-user.sql  &>>$LOG_FILE
    mysql -h mysql.daws84s.site -uroot -p$MYSQL_ROOT_PASSWORD < /app/db/master-data.sql &>>$LOG_FILE
    VALIDATE $? "Loading data into MySQL"
else
    echo -e "Data is already loaded into MySQL ... $Y SKIPPING $N"
fi

systemctl restart shipping &>>$LOG_FILE
VALIDATE $? "restarting shipping" 

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))

echo -e "Script execution completed successfully..$Y total time-taken $TOTAL_TIME:seconds $N " | tee -a $LOG_FILE

