#!/bin/bash

#File path
input="/tmp/serverlist"

#Generate the Serverlist file
aws ssm describe-instance-information \
--region eu-central-1 \
--query 'InstanceInformationList[].{InstanceId:InstanceId,PrivateIP:IPAddress,PlatformName:PlatformName}' \
--output text > $input
 

while IFS= read -r line
do
  inst="$(echo "$line" | awk '{print $1}')"
  
  #echo $inst 

servername="$(aws ec2 describe-instances \
 --instance-id $inst \
 --query 'Reservations[*].Instances[*].{ServerName:Tags[?Key==`Name`]}' \
 --output text | awk '{print $3}')"

	if [ -z "$servername" ]
		then
			sed -i "/^$inst/ s/$/\t<NAME-NOT-AVAIALBLE>/" $input
		else
			echo "Adding server name $servername to $inst"
			sed -i "/^$inst/ s/$/\t$servername/" $input
	fi

appname="$(aws ec2 describe-instances \
 --instance-id $inst \
 --query 'Reservations[*].Instances[*].{ServerName:Tags[?Key==`app:name`]}' \
 --output text | awk '{print $3}')"


	if [ -z "$appname" ]
		then
			echo "App name tag not available for $servername"
			sed -i "/^$inst/ s/$/\t<APP-TAG-NOT-AVAIALBLE>/" $input
		else
			echo "Adding app name $appname to $servername"
			sed -i "/^$inst/ s/$/\t$appname/" $input
	fi

 
done < "$input"
  
  cat $input