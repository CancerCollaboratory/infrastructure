#!/bin/bash
# Script to compare number of ceph rbd's to cinder's inventory. Use with Zabbix.
# Status 0 = No discrepencies, Status 1 = Discrepencies, please investigate
# Jared Baker 2016/10/17
rm /tmp/rbdcindervolcompare
#source /root/openrc-admin
export OS_USERNAME="xxx"
export OS_PASSWORD="xxx"
export OS_TENANT_NAME="admin"
export OS_PROJECT_DOMAIN_ID="default"
export OS_USER_DOMAIN_ID="default"
export OS_IDENTITY_API_VERSION=3
export OS_AUTH_URL=https://www.yyy.zzz:5000/v3/
openstack volume list --all -f value | awk '{print $1}' >> /tmp/rbdcindervolcompare
rbd -p volumes ls | sed "s/volume-//" >> /tmp/rbdcindervolcompare
var=`sort /tmp/rbdcindervolcompare | uniq -u`
if [ -z "$var" ];
then echo 0
else echo $var >> /var/log/volumes_left_out.txt
echo 1
fi
