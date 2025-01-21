#cloud-config
output: { all: "| tee -a /var/log/cloud-init-output.log" }
preserve_hostname: false
manage_etc_hosts: false
fqdn: ${hostname}.${domain}
package_update: true
package_upgrade: true
package_reboot_if_required: true
write_files:
  - path: /etc/amazon/ssm/seelog.xml
    encoding: text/plain
    owner: root:root
    permissions: '0644'
    content: |
      <!--amazon-ssm-agent uses seelog logging -->
      <!--Seelog has github wiki pages, which contain detailed how-tos references: https://github.com/cihub/seelog/wiki -->
      <!--Seelog examples can be found here: https://github.com/cihub/seelog-examples -->
      <seelog type="adaptive" mininterval="2000000" maxinterval="100000000" critmsgcount="500" minlevel="info">
          <exceptions>
              <exception filepattern="test*" minlevel="error"/>
          </exceptions>
          <outputs formatid="fmtinfo">
              <console formatid="fmtinfo"/>
              <rollingfile type="size" filename="/var/log/amazon/ssm/amazon-ssm-agent.log" maxsize="30000000" maxrolls="5"/>
              <filter levels="error,critical" formatid="fmterror">
                  <rollingfile type="size" filename="/var/log/amazon/ssm/errors.log" maxsize="10000000" maxrolls="5"/>
              </filter>
          </outputs>
          <formats>
              <format id="fmterror" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
              <format id="fmtdebug" format="%Date %Time %LEVEL [%FuncShort @ %File.%Line] %Msg%n"/>
              <format id="fmtinfo" format="%Date %Time %LEVEL %Msg%n"/>
          </formats>
      </seelog>
  - path: /root/.ssh/authorized_keys
    encoding: text/plain
    owner: root:root
    permissions: '0600'
    content: |
      ${id_rsa_pub}
  - path: /root/.ssh/id_rsa
    encoding: text/plain
    owner: root:root
    permissions: '0600'
    content: |
      ${id_rsa}
  - path: /root/.ssh/id_rsa.pub
    encoding: text/plain
    owner: root:root
    permissions: '0644'
    content: |
      ${id_rsa_pub}
  - path: /tmp/nodeConfig.yaml
    encoding: text/plain
    owner: root:root
    permissions: '0644'
    content: |
      apiVersion: node.eks.aws/v1alpha1
      kind: NodeConfig
      spec:
        cluster:
          name: ${cluster_name}
          region: ${region}
        hybrid:
          ssm:
            activationCode: ${activation_code}
            activationId: ${activation_id}
  - path: /tmp/ciliumValues.yaml
    encoding: text/plain
    owner: root:root
    permissions: '0644'
    content: |
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
          clusterPoolIPv4MaskSize: ${cluster_pool_ipv4_mask_size}
          clusterPoolIPv4PodCIDRList:
          - ${cluster_pool_ipv4_pod_cidr_list}
      operator:
        unmanagedPodWatcher:
          restart: false
runcmd:
  - echo "*******************************************************************************"
  - echo " Install and Configure the AWS CLI..."
  - echo "*******************************************************************************"
  - snap install aws-cli --classic
  - aws configure set region ${region}
  - aws configure set aws_access_key_id ${aws_access_key_id}
  - aws configure set aws_secret_access_key ${aws_secret_access_key}
  - aws configure set aws_session_token ${aws_session_token}
  - echo "*******************************************************************************"
  - echo " Install and Configure the AWS SSM Agent..."
  - echo "*******************************************************************************"
  - snap install amazon-ssm-agent --classic
  - /snap/amazon-ssm-agent/current/amazon-ssm-agent -register -code <activation code> -id <activation id> -region ${region}
  - echo "*******************************************************************************"
  - echo " Install Hybrid Node Dependencies and Connect to Cluster..."
  - echo "*******************************************************************************"
  - curl -O /tmp/nodeadm -L 'https://hybrid-assets.eks.amazonaws.com/releases/latest/bin/linux/amd64/nodeadm'
  - chmod +x /tmp/nodeadm
  - /tmp/nodeadm install ${kubernetes_version} --credential-provider ssm
  - ./nodeadm init -c file:///tmp/nodeConfig.yaml
  - echo "*******************************************************************************"
  - echo " Install and Configure Helm and Container Networking Interface..."
  - echo "*******************************************************************************"
  - snap install helm --classic
  - helm repo add cilium https://helm.cilium.io/
  - aws eks update-kubeconfig --name ${cluster_name} --region ${region}
  - helm install cilium cilium/cilium --version ${cilium_version} --namespace kube-system --values /tmp/ciliumValues.yaml --set k8sServiceHost=${k8s_service_host} --set k8sServicePort=${k8s_service_port}
  - echo "*******************************************************************************"
  - echo "User Data Script Execution Complete"
  - echo "*******************************************************************************"
