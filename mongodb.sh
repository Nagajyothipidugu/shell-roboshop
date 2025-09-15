#!/bin/bash 
USERID=$(id -u)
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m" 
 
LOGS_FOLDER="/var/log/roboshop-logs"
SCRIPT_NAME=$(echo $0 |cut -d "." -f1 )
LOG_FILE="$LOGS_FOLDER/$SCRIPT_NAME.log"
PACKAGES=("mysql" "nginx" "python3" "httpd" )

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
cp mongo.repo  /etc/yum.repos.d/mongo.repo
VALIDATE $? "copying mongo.repo content 

dnf install mongodb-org -y 
VALIDATE $? "Installing mongodb is"

systemctl enable mongod 
VALIDATE $? "enabling mongodb is"
systemctl start mongod 
VALIDATE $? "starting  mongodb is"  

sed -i 's/127.0.0.1 /0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Editing mongod conf file for remote connections" 

systemctl restart mongod
VALIDATE $? "restarting mongodb" 


