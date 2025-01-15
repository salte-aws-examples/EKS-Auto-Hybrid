#!/bin/bash

# Normalize Input Command
COMMAND=$(echo "$1" | tr '[:upper:]' '[:lower:]')

# Validate Inputs
if [ -z "$COMMAND" ] || ([ "$COMMAND" != "validate" ] &&  [ "$COMMAND" != "plan" ] && [ "$COMMAND" != "apply" ] && [ "$COMMAND" != "destroy" ]); then
  echo "You must pass one of the following arguments to this script: validate, plan, apply, destroy."
  exit 1
fi

# Changes Must Be Commited Before Apply
if [ ! -z $SKIP_COMMIT_CHECK ]; then
  COMMITTED=$(git status | grep "nothing to commit, working tree clean")
  if [ -z "$COMMITTED" ] && [ "$COMMAND" == "apply" ]; then
    echo "You must commit your code before running apply!"
    exit 2
  fi
fi

# Bootstrap Environment
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
if [ -f "$DIR/bootstrapEnvironment.sh" ]; then
  . $DIR/bootstrapEnvironment.sh
else
  echo "Error: The bootstrap environment script is missing!"
  echo "Follow the instructions included at the top of $DIR/bootstrapEnvironment.template.sh."
  exit 3
fi

# Finalize Environment
if [ -f "$DIR/../finalizeEnvironment.sh" ]; then
  . $DIR/../finalizeEnvironment.sh
else
  echo "Error: The finalize environment script is missing!"
  exit 4
fi

cd $DIR/../src

rm -rf .terraform/

INIT=`date`

terraform init -backend-config="bucket=$BUCKET" -backend-config="key=$GITHUB_REPOSITORY" -backend-config="encrypt=true" -backend-config="kms_key_id=$KMS_KEY_ID" -backend-config="dynamodb_table=$DYNAMODB_TABLE"

APPLY=`date`

terraform $@

FINISHED=`date`

echo $INIT$'\t'Terraform Init Started
echo $APPLY$'\t'Terraform $COMMAND Started
echo $FINISHED$'\t'Terraform $COMMAND Finished
