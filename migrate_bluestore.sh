#!/bin/bash

# Author: George Mihaiescu, July 24, 2018
# The purpose of this script is to stop all ceph-osd processes, unmount the drives, zap them and prepare/activate them as bluestore
rm /tmp/osds_to_prepare
rm /tmp/osds

# first obtain the current OSD IDs and drive names
echo "First, let's generate a list of the existing OSD IDs and drives in /tmp/osds."
df -h | grep ceph > /tmp/osds

# second, create a list of OSD IDs
echo ""
echo "Second, let's stop all the existing OSD processes."
list_osds=`cat /tmp/osds | awk '{print $6}' | awk -F'-' '{print $2;fflush(stdout)}' | sort -n`
for id in $list_osds; do systemctl stop ceph-osd@$id.service; done

# third, unmount the drives after we make sure there are no more OSD processes running
echo ""
check=`ps aux | grep -i osd | egrep -v grep  | wc -l`
if [ $check -ne 0 ]
then echo "There are still some OSD processes running, existing."
ps aux | grep -i osd | egrep -v grep
exit 1
fi

echo ""
echo "Third, let's unmount all the existing OSD drives."
list_drives=`cat /tmp/osds | awk '{print $6}'`
for drive in $list_drives; do umount $drive; done

# fourth, zap the drives
echo ""
echo "Fourth, let's zap all the existing OSD drives."
list_to_zap=`cat /tmp/osds | awk '{print $1}' | sed 's/1//'`
#for drive_to_zap in $list_to_zap; do echo "ceph-disk zap $drive_to_zap";sleep 3; done
for drive_to_zap in $list_to_zap; do ceph-disk zap $drive_to_zap; sleep 3; done

# fifth, generate the command that needs to be run on ceph-mon to destroy the old OSDs
echo ""
echo "Fifth, generate the command that needs to be run on ceph-mon to destroy the old OSDs"
list_to_destroy=`cat /tmp/osds | awk '{print $6}' | awk -F'-' '{print $2;fflush(stdout)}'`
for osd_to_destroy in $list_to_destroy; do echo "ceph osd destroy $osd_to_destroy --yes-i-really-mean-it"; done

# sixth, generate the commands to prepare the bluestore OSDs
#echo ""
#echo "Sixth, generate the commands to prepare the bluestore OSDs"
#cat /tmp/osds | awk '{print $1,$6}'| sed 's/1//' | awk -F"-" '{print $1, $2}' | awk '{print $1, $3}' | sort -k 2 -n >>  /tmp/osds_to_prepare
#while read osd id;\
#do echo "ceph-disk prepare --bluestore $osd --osd-id $id";
