create_vpc=false
create_account_roles=true
create_operator_roles=true
cluster_name="{{ kerberos_name }}-{{ openshift_cluster_name_suffix }}-c"
multi_az=true
aws_region="{{ aws_region }}"
vpc_cidr_block="{{ disconnected_vpc_cidr }}"
aws_subnet_ids=["{{ disconnected_subnet_id_a }}", "{{ disconnected_subnet_id_b }}", "{{ disconnected_subnet_id_c }}"]
rosa_openshift_version="{{ openshift_major_version }}.{{ openshift_minor_version }}"
proxy = {
   http_proxy = "http://{{ installer_quay_hostname.stdout }}:3128"
   https_proxy = "http://{{ installer_quay_hostname.stdout }}:3128"
}
private_cluster = true
