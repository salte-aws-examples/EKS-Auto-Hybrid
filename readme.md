# Project Description
---
Provisions an AWS EKS Cluster with Auto Mode enabled and Hybrid Node support.  The provisioned cluster is configured to run Kubernetes 1.31, which requires version 1.16 of the Cilium Container Networking Interface to be configured on all associated hybrid nodes.

# Deploying the EKS Cluster
---
## Prerequisites
Must have private connectivity between the target AWS environment and the site where hybrid nodes will be deployed.
## Input Variables
| Variable | Value |
| -------- | ----- |
| AWS_ACCESS_KEY_ID | Administrator Credential for the target AWS account. |
| AWS_SECRET_ACCESS_KEY | Administrator Credential for the target AWS account. |
| TF_VAR_remote_node_network | Provide the CIDR range for the network where hybrid nodes will run. |
| TF_VAR_remote_pod_network | Provide the CIDR range that individual Pod networks running on hybrid nodes will draw from. |
## Deployment Steps
1. Copy _local/boostrapEnvironment.template.sh to _local/bootstrapEnvironment.sh
2. Populate the previous listed environment variables in the file just created.
3. Run "_local/runTerraform.sh apply -auto-approve" from the project root directory.

# Deploying the Hybrid Node
---
## Prerequisites
* Must have a Linux server running on the network indicated by the TF_VAR_remote_node_network environment variable.
* The Linux server must be running one of the following operating systems: AWS Linux 2023, Ubuntu 20.04-24.04, or Redhat 8 or 9.
* Must have command line credentials with administrative permissions to the AWS account that hosts the EKS Cluster Control Plane.
* Must select a CIDR range from the remote pod network range supplied to the EKS Cluster when it was provisioned.
* Must have the provisioned EKS Cluster's API DNS name.
## Configuration Files Required
### nodeConfig.yaml
```yaml
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: default-cluster
    region: us-east-1
  hybrid:
    ssm:
      activationCode: <activation code>
      activationId: <activation id>
```
### ciliumValues.yaml
```yaml
affinity:
  nodeAffinity:
    requiredDuringSchedulingIgnoredDuringExecution:
      nodeSelectorTerms:
      - matchExpressions:
        - key: eks.amazonaws.com/compute-type
          operator: In
          values:
          - hybrid
ipam:
  mode: cluster-pool
  operator:
    clusterPoolIPv4MaskSize: 25
    clusterPoolIPv4PodCIDRList:
    - <Pod CIDR Range>
operator:
  unmanagedPodWatcher:
    restart: false
```
## Hybrid Node Setup Steps
Placeholder values should be updated with the corresponding values mentioned in the prerequisites section above.
```sh
dave@eks-hybrid-node:~# sudo su
root@eks-hybrid-node:~# snap install aws-cli --classic
root@eks-hybrid-node:~# export AWS_DEFAULT_REGION=us-east-1
root@eks-hybrid-node:~# export AWS_ACCESS_KEY_ID=<AWS_ACCESS_KEY_ID>
root@eks-hybrid-node:~# export AWS_SECRET_ACCESS_KEY=<AWS_SECRET_ACCESS_KEY>
root@eks-hybrid-node:~# aws ssm create-activation --default-instance-name eks-hybrid-node --description "On-premises EKS node running under Proxmox." --iam-role default-eks-hybrid-node-role --registration-limit 1 --region us-east-1
root@eks-hybrid-node:~# snap install amazon-ssm-agent --classic
root@eks-hybrid-node:~# /snap/amazon-ssm-agent/current/amazon-ssm-agent -register -code <activation code> -id <activation id> -region us-east-1
root@eks-hybrid-node:~# curl -OL 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm'
root@eks-hybrid-node:~# chmod +x nodeadm
root@eks-hybrid-node:~# ./nodeadm install 1.31 --credential-provider ssm
root@eks-hybrid-node:~# ./nodeadm init -c file:///root/nodeConfig.yaml
root@eks-hybrid-node:~# snap install helm --classic
root@eks-hybrid-node:~# helm repo add cilium https://helm.cilium.io/
root@eks-hybrid-node:~# aws eks update-kubeconfig --name default-cluster --region us-east-1
root@eks-hybrid-node:~# helm install cilium cilium/cilium --version 1.16 --namespace kube-system --values ciliumValues.yaml --set k8sServiceHost=<API Server DNS Name> --set k8sServicePort=443
```
