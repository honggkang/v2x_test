#!/bin/bash

set -x 

# choose a freq
ifconfig $1 up
iw $1 scan 
iw list | grep MHz 
echo "Set the freq : "
read freq

# set ID according to the board number 
ID=100 

iw dev $1 set type ibss 
iw $1 ibss join dronemesh-adhoc $freq

modprobe batman-adv
batctl if add $1
ifconfig $1 mtu 1527
cat /sys/class/net/$1/batmand_adv/iface_status

ifconfig $1 192.168.0.$ID
ifconfig bat0 10.10.0.$ID

ifconfig bat0 up
