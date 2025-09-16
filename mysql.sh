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

dnf install mysql-server -y &>>LOG_FILE
VALIDATE $? "Installing mysql"

systemctl enable mysqld &>>LOG_FILE
VALIDATE $? "Enabling mysql"
systemctl start mysqld  &>>LOG_FILE
VALIDATE $? "Start mysql" 

mysql_secure_installation --set-root-pass $MYSQL_ROOT_PASSWORD &>>LOG_FILE
VALIDATE $? "setting up the root password"

END_TIME=$(date +%s)
TOTAL_TIME=$(( $END_TIME - $START_TIME))

echo -e "Script execution completed successfully..$Y total time-taken $TOTAL_TIME:seconds $N " | tee -a $LOG_FILE