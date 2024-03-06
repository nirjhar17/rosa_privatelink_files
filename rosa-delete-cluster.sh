#!/bin/bash
OID_CONFIG_ID=`rosa describe cluster -c {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c | grep "OIDC Endpoint URL" | awk {'print $4'} | cut -f4 -d/`

rosa delete cluster \
  --cluster {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c \
  --yes \
  --region {{ aws_region }} 

rosa logs uninstall \
  -c {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c \
  --watch

rosa delete operator-roles \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c \
  --mode auto \
  --yes

rosa delete account-roles \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }} \
  --mode auto \
  --yes

rosa delete oidc-provider \
  --oidc-config-id $OID_CONFIG_ID \
  --mode auto \
  --yes
