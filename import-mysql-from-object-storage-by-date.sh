#!/bin/bash

read -p "Enter database backup date: " inputdate

db_date=$inputdate

# object storage
bucket_name=bucket-name
object_url=${bucket_name}'.ap-south-1.linodeobjects.com' #example
access_key=''
secret_key=''

# mysql
mysql_host='localhost'
mysql_port=3306
mysql_user='user'
mysql_password='password'

# checking on object storage if the folder exists
count=`s3cmd ls s3://${bucket_name}/${db_date}/ | wc -l`

if [[ $count -eq 0 ]]; then
    echo "Backup folder doesn't exist"
    exit
fi

# download db from object storage
echo "Downloading database from object storage ..."
temporary_folder='/your/temporary/path'

mkdir -p ${temporary_folder}/${db_date}

s3cmd get --recursive --quiet s3://${bucket_name}/${db_date}/ ${temporary_folder}/${db_date}/
ls ${temporary_folder}/${db_date}/ > databaselist.txt

echo " "

echo "Restore to the database ..."
cat databaselist.txt | while read line
do
db_file=$line
	if [[ ! $line =~ "schema" ]] ;
		then
			gunzip ${temporary_folder}/${db_date}/${db_file}
			file_name=${db_file}	
			IFS="-" read -r -a array <<< "$file_name"
			db_name=${array[0]}
			echo "o Importing from ${db_file} ..."
			mysql -u ${mysql_user} -h ${mysql_host} -P ${mysql_port} -p${mysql_password} ${db_name} < ${file_name}
			echo " "
	fi
done
rm databaselist.txt
rm -rf ${temporary_folder}
echo "Done ..."
