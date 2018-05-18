#!/bin/bash

# This script takes the service name as input and returns 1 if the API responds ok, or 0 if it doesn't.

# Define openstack credentials
export OS_USERNAME="admin"
export OS_PASSWORD="xxx"
export OS_TENANT_NAME="admin"
export OS_AUTH_URL="https://xxx.yyy.zzz:5000/v3/"

# Generate token
TOKEN=`openstack token issue -f value -c id`
APITEST=$1
APIIP="xxx.yyy.zzz"
PROJECT_ID="xxxxxxxxxxxxxx"

if [ ${APITEST} = "cinder" ]
  then response=`curl -g -s -X GET https://$APIIP:8776/v2/${PROJECT_ID}/volumes/detail -H "User-Agent: python-cinderclient" -H "Accept: application/json" -H "X-Auth-Token: $TOKEN"| grep -c volumes`
  elif [ ${APITEST} = "neutron" ]
  then response=`curl -g -s -X GET https://$APIIP:9696/v2.0/networks/${PROJECT_ID} -H "User-Agent: openstacksdk/0.9.9 keystoneauth1/2.15.0 python-requests/2.5.1 CPython/2.7.6 Linux/3.13.0-107-generic CPython/2.7.6" -H "Accept: application/json" -H "X-Auth-Token: $TOKEN"| grep -c admin_state_up`
  elif [ ${APITEST} = "glance" ]
  then response=`curl -g -s -X GET https://$APIIP:9292/v2/images -H "User-Agent: osc-lib keystoneauth1/2.15.0 python-requests/2.5.1 CPython/2.7.6 Linux/3.13.0-107-generic CPython/2.7.6" -H "X-Auth-Token: $TOKEN" | grep -c images`
  elif [ ${APITEST} = "nova" ]
  then response=`curl -g -s -X GET https://$APIIP:8774/v2.1/${PROJECT_ID}/servers/detail -H "User-Agent: python-novaclient" -H "Accept: application/json" -H "X-Auth-Token: $TOKEN" | grep -c servers`
  elif [ ${APITEST} = "keystone" ]
  then response=`openstack token issue | grep -c user_id`
fi

if [ $response -eq 1 ]
then echo $response
exit 0
fi
echo 0
