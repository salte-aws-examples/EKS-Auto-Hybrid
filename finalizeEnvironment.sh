#!/bin/bash

# *****************************************************************************
# Overridable Variables
# *****************************************************************************
if [ -z "$AWS_REGION" ]; then
  export AWS_REGION="us-east-1"
fi

# *****************************************************************************
# Derived Variables
# *****************************************************************************
ACCOUNT=`aws sts get-caller-identity --query Account --output text`
export BUCKET="${AWS_REGION}-${ACCOUNT}-terraform-state"
export KEY="$GITHUB_REPOSITORY"
export DYNAMODB_TABLE="terraform-statelock"
export KMS_KEY_ID="arn:aws:kms:${AWS_REGION}:${ACCOUNT}:alias/${AWS_REGION}-${ACCOUNT}-terraform-state"
