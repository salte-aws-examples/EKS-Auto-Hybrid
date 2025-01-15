#!/bin/bash

#######################################################################################
# Steps:
# 1. Copy this file to bootstrapEnvironment.sh.
# 2. Populate the environment variables listed below.
# 3. Run ./_local_only/runTerraform.sh validate|plan|apply|destroy from the project root.
#
# Note:
# Any action taken will affect the environment tied to the branch you are currently on.
#######################################################################################
# AWS Provider Variables
export AWS_DEFAULT_REGION=us-east-1
export AWS_ACCESS_KEY_ID=
export AWS_SECRET_ACCESS_KEY=

# Simulate Default Github Action Runner Variables
export GITHUB_REF=refs/heads/$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo development)
export GITHUB_REPOSITORY=salte-aws-examples/EKS-Auto-Hybrid
export GITHUB_SHA=$(git rev-parse HEAD 2>/dev/null || echo 0000000000000000000000000000000000000000)

# Inputs defined in the root inputs.tf file.
export TF_VAR_commit=$GITHUB_SHA
export TF_VAR_remote_node_network=
export TF_VAR_remote_pod_network=
export TF_VAR_repository=$GITHUB_REPOSITORY

# Debugging
# export SKIP_COMMIT_CHECK=YES
# export TF_LOG=TRACE
# export TF_LOG_PATH=terraform.log
