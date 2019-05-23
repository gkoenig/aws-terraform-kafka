#!/usr/bin/env bash

set -euo pipefail

# this script allows switching AWS user to corresponding role of your project (e.g. engineer, owner, admin ...)
source $(dirname $0)/_config

cat << AWS_LOGIN

================================================================================

  Login into AWS:

  IAM account:    $aws_iam_account_id
  AWS user:       $aws_user_id

  Role account:   $aws_role_account_id
  Role name:      $aws_role

================================================================================

AWS_LOGIN

# request MFA token from command line because it expires after 1 minute
echo -n "Enter MFA code from your device: "
read tokencode

# unset all env vars
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

# auth with iam user account to get temporary credentials for setting up the cluster
credentials_user=$(aws sts get-session-token --serial-number arn:aws:iam::${aws_iam_account_id}:mfa/${aws_user_id} --token-code ${tokencode})

# set the new genereted credentials to the CLI environment variables for future usage
export AWS_ACCESS_KEY_ID=$(echo ${credentials_user} | jq -r '.Credentials .AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo ${credentials_user} | jq -r '.Credentials .SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo ${credentials_user} | jq -r '.Credentials .SessionToken')

# change role to the role belonging to your project (owner, admin, engineer, ...)
credentials_role=$(aws sts assume-role --role-arn arn:aws:iam::${aws_role_account_id}:role/${aws_role} --role-session-name "RoleSession1")

# reset the aws environment variables with the data belonging to your selected role
export AWS_ACCESS_KEY_ID=$(echo ${credentials_role} | jq -r '.Credentials .AccessKeyId')
export AWS_SECRET_ACCESS_KEY=$(echo ${credentials_role} | jq -r '.Credentials .SecretAccessKey')
export AWS_SESSION_TOKEN=$(echo ${credentials_role} | jq -r '.Credentials .SessionToken')

aws configure set aws_access_key_id $AWS_ACCESS_KEY_ID --profile engineer_mfa
aws configure set aws_secret_access_key $AWS_SECRET_ACCESS_KEY --profile engineer_mfa
aws configure set aws_session_token $AWS_SESSION_TOKEN --profile engineer_mfa
