#!/bin/bash -e
# Log script output to a file while preserving output to the terminal
exec 1> >(tee -a /var/log/image_refresh.log) 2>&1
# Prints the date, used for logging purposes
date
# Source Openstack credentials
source /path/to/your/credentials
UPDATE=$1 # Arguments
PTH="/tmp/" # Working directory
EMAIL="no"
REPORT="image_refresh_report.txt"

# Get list of checksum files
wget -q https://cloud-images.ubuntu.com/releases/14.04/release/SHA256SUMS -O ${PTH}checksums_UBUNTU_14
wget -q https://cloud-images.ubuntu.com/releases/16.04/release/SHA256SUMS -O ${PTH}checksums_UBUNTU_16
wget -q http://cloud.centos.org/centos/7/images/sha256sum.txt -O ${PTH}checksums_CENTOS_7
wget -q http://cdimage.debian.org/cdimage/openstack/current/SHA256SUMS -O ${PTH}checksums_DEBIAN_8

# Get checksums from online images
OCS_U14=`grep "ubuntu-14.04-server-cloudimg-amd64-disk1.img$" ${PTH}checksums_UBUNTU_14 | awk '{print $1}'`
OCS_U16=`grep "ubuntu-16.04-server-cloudimg-amd64-disk1.img$" ${PTH}checksums_UBUNTU_16 | awk '{print $1}'`
OCS_C7=`tail -4 ${PTH}checksums_CENTOS_7 | head -1 | awk '{print $1}'`
OCS_D8=`egrep "debian.*amd.*.qcow2$" ${PTH}checksums_DEBIAN_8 | awk '{print $1}'`
D8_FILE=`egrep "debian.*amd.*.qcow2$" ${PTH}checksums_DEBIAN_8 | awk '{print $2}'`

# Define distribution image location
UBUNTU_14="https://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img"
UBUNTU_16="https://cloud-images.ubuntu.com/releases/16.04/release/ubuntu-16.04-server-cloudimg-amd64-disk1.img"
CENTOS_7="http://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
DEBIAN_8="http://cdimage.debian.org/cdimage/openstack/current/${D8_FILE}"

# Get checksums from current openstack images
CS_U14=`openstack image show -c properties -f value "Ubuntu 14.04 - latest" | awk -F'=' '{print $4}'| awk -F"'" '{print $2}'`
CS_U16=`openstack image show -c properties -f value "Ubuntu 16.04 - latest" | awk -F'=' '{print $4}'| awk -F"'" '{print $2}'`
CS_C7=`openstack image show -c properties -f value "CentOS 7 - latest" | awk -F'=' '{print $4}'| awk -F"'" '{print $2}'`
CS_D8=`openstack image show -c properties -f value "Debian 8 - latest" | awk -F'=' '{print $4}'| awk -F"'" '{print $2}'`

echo -n "" > ${PTH}${REPORT} # Clear the reporting file instead of deleting since it will throw errors if the file doesnt exist

if [ "${UPDATE}" = "--update" ]; then
    echo "RUNNING SCRIPT IN UPDATE MODE"
fi

# Compare checksums and create the new image if checksum does not match
# Ubuntu 14.04
if [ ${CS_U14} = ${OCS_U14} ]
	then echo "Ubuntu 14.04 online checksum matches local, nothing to do"
	else
	echo "Ubuntu 14.04 Update available. Run with --update" && echo "Ubuntu 14.04 is out of date" >> ${PTH}${REPORT}
	EMAIL=yes
		if [ "${UPDATE}" = "--update" ]
			then
			echo "Ubuntu 14.04 online checksum does not match local, downloading new image"
			wget -q ${UBUNTU_14} -P ${PTH}
			LCS_U14=`sha256sum ${PTH}ubuntu-14.04-server-cloudimg-amd64-disk1.img | awk '{print $1}'`
				if [ ${OCS_U14} = ${LCS_U14} ] # Validate downloaded file
					then echo "Ubuntu 14.04 local checksums match, creating new glance image"
					else echo "Ubuntu 14.04 local checksum [${LCS_U14}] does not match online checksum [${OCS_U14}], please investigate"
					exit 1
				fi
			openstack image create --container-format bare --disk-format qcow2 --file ${PTH}ubuntu-14.04-server-cloudimg-amd64-disk1.img --property description='Default user is "ubuntu" and access is only allowed using ssh keys.' --property sha256=${LCS_U14} --public "Ubuntu 14.04 - latest.tmp"
			openstack image delete "Ubuntu 14.04 - latest" && openstack image set "Ubuntu 14.04 - latest.tmp" --name "Ubuntu 14.04 - latest"
		fi
fi

# Ubuntu 16.04
if [ ${CS_U16} = ${OCS_U16} ]
	then echo "Ubuntu 16.04 online checksum matches local, nothing to do"
	else
	echo "Ubuntu 16.04 Update available. Run with --update" && echo "Ubuntu 16.04 is out of date" >> ${PTH}${REPORT}
	EMAIL=yes
	if [ "${UPDATE}" = "--update" ]
                then
		echo "Ubuntu 16.04 online checksum does not match local, downloading new image"
		wget -q ${UBUNTU_16} -P ${PTH}
        	LCS_U16=`sha256sum ${PTH}ubuntu-16.04-server-cloudimg-amd64-disk1.img | awk '{print $1}'`
                	if [ ${OCS_U16} = ${LCS_U16} ] # Validate downloaded file
                        	then echo "Ubuntu 16.04 local checksums match, creating new glance image"
                        	else echo "Ubuntu 16.04 local checksum [${LCS_U16}] does not match online checksum [${OCS_U16}], please investigate"
				exit 1
                	fi
		openstack image create --container-format bare --disk-format qcow2 --file ${PTH}ubuntu-16.04-server-cloudimg-amd64-disk1.img --property description='Default user is "ubuntu" and access is only allowed using ssh keys.' --property sha256=${LCS_U16} --public "Ubuntu 16.04 - latest.tmp"
        	openstack image delete "Ubuntu 16.04 - latest" && openstack image set "Ubuntu 16.04 - latest.tmp" --name "Ubuntu 16.04 - latest"
	fi
fi

# CentOS 7
if [ ${CS_C7} = ${OCS_C7} ]
	then echo "CentOS 7 online checksum matches local, nothing to do"
	else
	echo "CentOS 7 Update available. Run with --update" && echo "CentOS 7 is out of date" >> ${PTH}${REPORT}
	EMAIL=yes
	if [ "${UPDATE}" = "--update" ]
                then
		echo "CentOS 7 online checksum does not match local, downloading new image"
		wget -q ${CENTOS_7} -P ${PTH}
		LCS_C7=`sha256sum ${PTH}CentOS-7-x86_64-GenericCloud.qcow2 | awk '{print $1}'`
                if [ ${OCS_C7} = ${LCS_C7} ] # Validate downloaded file
                        then echo "CentOS 7 local checksums match, creating new glance image"
                        else echo "CentOS 7 local checksum [${LCS_C7}] does not match online checksum [${OCS_C7}] please investigate"
			exit 1
                fi
		openstack image create --container-format bare --disk-format qcow2 --file ${PTH}CentOS-7-x86_64-GenericCloud.qcow2 --property description='Default user is "centos" and access is only allowed using ssh keys.', --property sha256=${LCS_C7} --public "CentOS 7 - latest.tmp"
        	openstack image delete "CentOS 7 - latest" && openstack image set "CentOS 7 - latest.tmp" --name "CentOS 7 - latest"
	fi
fi

# Debian 8
if [ ${CS_D8} = ${OCS_D8} ]
	then echo "Debian 8 online checksum matches local, nothing to do"
	else
	echo "Debian 8 Update available. Run with --update" && echo "Debian 8 is out of date" >> ${PTH}${REPORT}
	EMAIL=yes
	if [ "${UPDATE}" = "--update" ]
                then
		echo "Debian 8 online checksum does not match local, downloading new image"
		wget -q ${DEBIAN_8} -P ${PTH}
		LCS_D8=`sha256sum ${PTH}${D8_FILE} | awk '{print $1}'`
                if [ ${OCS_D8} = ${LCS_D8} ] # Validate downloaded file
                        then echo "Debian 8 local checksums match, creating new glance image"
                        else echo "Debian 8 local checksum [${LCS_D8}] does not match online checksum [${OCS_D8}], please investigate"
			exit 1
                fi
		openstack image create --container-format bare --disk-format qcow2 --file ${PTH}${D8_FILE} --property description='Default user is "debian" and access is only allowed using ssh keys.' --property sha256=${LCS_D8} --public "Debian 8 - latest.tmp"
        	openstack image delete "Debian 8 - latest" && openstack image set "Debian 8 - latest.tmp" --name "Debian 8 - latest"
	fi
fi
if [ ${EMAIL} = yes ]
	then /usr/lib/zabbix/alertscripts/gmail_alert.sh "your@email.address.here" "Glance Image refresh needed" "`cat ${PTH}${REPORT}`"
fi

# File cleanup
rm -f ${PTH}checksums_*
rm -f ${PTH}*.qcow2
rm -f ${PTH}*.img
echo -n "" > ${PTH}${REPORT}
exit
