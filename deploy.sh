#!/usr/bin/env bash

export AWS_DEFAULT_REGION=us-east-1
export AWS_REGION=us-east-1

set -e

function jsonval {
    temp=`echo $json | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $prop`
    echo ${temp##*|}
}

if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    exit 1
fi


ACCESS_KEY_ID=$1
SECRET_ACCESS_KEY=$2

USER_POOL="ClaimsAssistPool"
USER_POOL_CLIENT="ClaimsAssistApp"

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account Id is $ACCOUNT_ID"

BENEFIT_TABLE=$ACCOUNT_ID"_Benefits"
USER_TABLE=$ACCOUNT_ID"_Users"

aws dynamodb create-table \
    --table-name $BENEFIT_TABLE \
    --attribute-definitions \
        AttributeName=benefit,AttributeType=S \
        AttributeName=benefittype,AttributeType=S \
    --key-schema AttributeName=benefit,KeyType=HASH AttributeName=benefittype,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1

echo "Table created : $BENEFIT_TABLE"

aws dynamodb create-table \
    --table-name $USER_TABLE \
    --attribute-definitions \
        AttributeName=email,AttributeType=S \
        AttributeName=firstname,AttributeType=S \
    --key-schema AttributeName=email,KeyType=HASH AttributeName=firstname,KeyType=RANGE \
    --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
    
echo "Table created : $USER_TABLE"

json=$(aws cognito-idp create-user-pool \
                        --pool-name $USER_POOL) 
prop="Id"    
USER_POOL_ID=`jsonval`
USER_POOL_ID=${USER_POOL_ID//Id:/''}
echo "User Pool Created : $USER_POOL with Id : $USER_POOL_ID"

json=$(aws cognito-idp create-user-pool-client \
        --user-pool-id $USER_POOL_ID \
        --client-name $USER_POOL_CLIENT)
prop="ClientId"         
USER_POOL_CLIENT_ID=`jsonval`
USER_POOL_CLIENT_ID=${USER_POOL_ID//ClientId:/''}
echo "User Pool Client Created : $USER_POOL_CLIENT_ID"

curl -O https://s3.ap-south-1.amazonaws.com/ggn-code-repo/SamRepositorySubmission/code.zip
unzip code.zip
claudia generate-serverless-express-proxy --express-module app
claudia create --handler lambda.handler --deploy-proxy-api --region us-east-1

