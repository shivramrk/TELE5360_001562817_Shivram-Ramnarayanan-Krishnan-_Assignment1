#! /bin/bash
 
if ! grep -q aws_access_key_id ~/.aws/config; then      
   if ! grep -q aws_access_key_id ~/.aws/credentials; then
      echo "AWS config not found or CLI is not installed"
      exit 1
    fi
fi
 
 
read -r -p "Enter the username to create": username
 
aws iam create-user --user-name "${username}" --output json
  
credentials=$(aws iam create-access-key --user-name "${username}" --query 'AccessKey.[AccessKeyId,SecretAccessKey]'  --output text)
 
 
access_key_id=$(echo ${credentials} | cut -d " " -f 1)
secret_access_key=$(echo ${credentials} | cut --complement -d " " -f 1)
  
 
echo "The Username "${username}" has been created"
echo "The access key ID  of "${username}" is $access_key_id "
echo "The Secret access key of "${username}" is $secret_access_key "
