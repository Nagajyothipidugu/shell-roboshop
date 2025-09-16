#!/bin/bash 
START_TIME=$(date %s)
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m" 
 
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"


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
     echo -e " $G $2   success... $N" | tee -a $LOG_FILE
    else 
     echo -e " $R $2   failure $N"  | tee -a $LOG_FILE
     exit 1

    fi
    }  
dnf module disable redis -y &>>LOG_FILE
VALIDATE $? "disabling redis"
dnf module enable redis:7 -y  &>>LOG_FILE 
VALIDATE $? "Enabling redis"  

dnf install redis -y  &>>LOG_FILE
VALIDATE $? "Installing redis"

sed -i -e 's/127.0.0.1/0.0.0.0/g' -e '/protected-mode/ c protected-mode no' /etc/redis/redis.conf &>>LOG_FILE
VALIDATE $? "edited reddis conf to accept remote connections"

systemctl enable redis  &>>LOG_FILE
VALIDATE $? "Enable reddis" 
systemctl start redis 
VALIDATE $? "start reddis"

END_TIME=$(date %s)
TOTAL_TIME=$( ( $START_TIME-$END_TIME ) )

echo -e "Script execution completed successfully..$Y $TOTAL_TIME  seconds $N " | tee -a $LOG_FILE

