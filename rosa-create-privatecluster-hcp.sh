#This policy contains the least privilege permissions required to create, manage, and delete ROSA clusters and roles in AWS.
```
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "RosaClusterAndRoleManagement",
      "Effect": "Allow",
      "Action": [
        "iam:GetRole",
        "iam:ListRoleTags",
        "iam:ListRoles",
        "iam:ListAttachedRolePolicies",
        "iam:AttachRolePolicy",
        "iam:UpdateAssumeRolePolicy",
        "iam:TagRole",
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:DetachRolePolicy",
        "iam:ListInstanceProfilesForRole",
        "iam:ListRolePolicies",
        "iam:GetPolicy",
        "iam:CreatePolicy",
        "iam:DeletePolicy",
        "iam:ListPolicyTags",
        "iam:ListPolicyVersions",
        "iam:ListOpenIDConnectProviders",
        "iam:TagOpenIDConnectProvider",
        "iam:CreateOpenIDConnectProvider",
        "iam:DeleteOpenIDConnectProvider",
        "elasticloadbalancing:DescribeAccountLimits",
        "servicequotas:ListServiceQuotas",
        "ec2:DescribeSubnets",
        "ec2:DescribeRouteTables",
        "ec2:DescribeAvailabilityZones",
        "s3:CreateBucket",
        "s3:PutObject",
        "s3:PutBucketTagging",
        "s3:PutBucketPolicy",
        "s3:PutObjectTagging",
        "s3:PutBucketPublicAccessBlock",
        "s3:ListBucket",
        "s3:DeleteObject",
        "s3:DeleteBucket",
        "secretsmanager:CreateSecret",
        "secretsmanager:TagResource",
        "secretsmanager:DeleteSecret"
      ],
      "Resource": "*"
    }
  ]
}
```

#!/bin/bash
echo "===== Logging in using ROSA Token ====="
rosa login --token={{ rosa_token }}

echo "===== Creating Account Roles ====="
rosa create account-roles \
  --hosted-cp \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }} \
  --mode auto \
  --yes

echo "===== Creating ODIC Config ID ====="
OIDC_CONFIG_ID=`rosa create oidc-config --mode=auto  --yes | grep oidc-provider | cut -f3 -d/ | cut -f1 -d\'`
echo "OIDC CONFIG ID: ${OIDC_CONFIG_ID}"

echo "===== Fetching AWS Account Number ====="
AWS_ACCOUNT_NUMBER=`aws sts get-caller-identity | grep Account | cut -f2 -d: |  cut -f1 -d,| cut -f2 -d\"`
echo "AWS ACCOUNT NUMBER: ${AWS_ACCOUNT_NUMBER}"

echo "===== Creating Operator Roles ====="
rosa create operator-roles \
  --hosted-cp \
  --prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h \
  --oidc-config-id $OIDC_CONFIG_ID \
  --installer-role-arn arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-HCP-ROSA-Installer-Role \
  --mode auto \
  --yes

echo "===== Creating ROSA Cluster {{ kerberos_name }}-{{ openshift_cluster_name_suffix }} ====="
rosa create cluster \
  --role-arn arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-HCP-ROSA-Installer-Role \
  --support-role-arn arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-HCP-ROSA-Support-Role \
  --worker-iam-role arn:aws:iam::${AWS_ACCOUNT_NUMBER}:role/{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-HCP-ROSA-Worker-Role \
  --operator-roles-prefix {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h \
  --oidc-config-id ${OIDC_CONFIG_ID} \
  --hosted-cp \
  --private-link \
  --sts \
  --mode auto \
  --multi-az \
  --cluster-name {{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-h \
  --machine-cidr {{ disconnected_vpc_cidr }} \
  --subnet-ids {{ disconnected_subnet_id_a }},{{ disconnected_subnet_id_b }},{{ disconnected_subnet_id_c }} \
  --additional-trust-bundle-file /etc/squid/certs/squid-ca-crt.pem \
  --http-proxy http://{{ installer_quay_hostname.stdout }}:3128 \
  --https-proxy http://{{ installer_quay_hostname.stdout }}:3128 \
  --no-proxy s3.dualstack.{{ aws_region }}.amazonaws.com,s3.{{ aws_region }}.amazonaws.com,ec2.{{ aws_region }}.amazonaws.com,elasticloadbalancing.{{ aws_region }}.amazonaws.com,sts.{{ aws_region }}.amazonaws.com \
  --yes \
  --region {{ aws_region }}
