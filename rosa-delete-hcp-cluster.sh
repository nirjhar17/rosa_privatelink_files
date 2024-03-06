#!/bin/bash

OID_CONFIG_ID=`rosa describe cluster -c {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h | grep "OIDC Endpoint URL" | awk {'print $4'} | cut -f4 -d/`

rosa delete cluster \
  --cluster {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h \
  --yes --region {{ aws_region }} 

rosa logs uninstall \
  -c {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h \
  --watch

rosa delete operator-roles \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h \
  --mode auto \
  --yes

rosa delete account-roles \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }} \
  --mode auto \
  --yes \
  --hosted-cp

rosa delete oidc-provider \
  --yes \
  --mode auto \
  --oidc-config-id $OID_CONFIG_ID
