#!/bin/bash

rosa login --token={{ rosa_token }}

rosa create account-roles \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }} \
  --mode auto \
  --yes

OIDC_CONFIG_ID=`rosa create oidc-config --mode=auto  --yes | grep oidc-provider | cut -f3 -d/ | cut -f1 -d\'`
AWS_ACCOUNT_NUMBER=`aws sts get-caller-identity | grep Account | cut -f2 -d: |  cut -f1 -d,| cut -f2 -d\"`

rosa create operator-roles \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c\
  --oidc-config-id $OIDC_CONFIG_ID \
  --installer-role-arn arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-Installer-Role \
  --mode auto \
  --yes

rosa create cluster \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-Installer-Role \
  --support-role-arn arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-Support-Role \
  --worker-iam-role arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-Worker-Role \
  --controlplane-iam-role arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-ControlPlane-Role \
  --oidc-config-id ${OIDC_CONFIG_ID} \
  --operator-roles-prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c \
  --private-link \
  --sts \
  --mode auto \
  --multi-az \
  --cluster-name {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c \
  --machine-cidr {{ disconnected_vpc_cidr }} \
  --subnet-ids {{ disconnected_subnet_id_a }},{{ disconnected_subnet_id_b }},{{ disconnected_subnet_id_c }} \
  --additional-trust-bundle-file /etc/squid/certs/squid-ca-crt.pem \
  --http-proxy http://{{ installer_quay_hostname.stdout }}:3128 \
  --https-proxy http://{{ installer_quay_hostname.stdout }}:3128 \
  --no-proxy s3.dualstack.{{ aws_region }}.amazonaws.com,s3.{{ aws_region }}.amazonaws.com,ec2.{{ aws_region }}.amazonaws.com,elasticloadbalancing.{{ aws_region }}.amazonaws.com,sts.{{ aws_region }}.amazonaws.com \
  --yes \
  --region {{ aws_region }}

## e.g --no-proxy s3.dualstack.ap-southeast-1.amazonaws.com,s3.ap-southeast-1.amazonaws.com,ec2.ap-southeast-1.amazonaws.com,elasticloadbalancing.ap-southeast-1.amazonaws.com,sts.ap-southeast-1.amazonaws.com
