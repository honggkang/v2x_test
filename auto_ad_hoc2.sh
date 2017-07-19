#!/bin/bash

set -x 

#service network-manager stop

i=$(ifconfig | grep wlan | awk '{print $1}')

ifconfig $i up

iw reg set KR

#iw $1 scan 
#iw list | grep MHz 
#echo "Set the freq : "
#read freq

freq=$(iw wlan1 scan | grep dronemesh -A 2 -B 8 | grep freq | awk '{print $2}')

# set ID according to the board number 
ID=1

killall wpa_supplicant 2> /dev/null

ifconfig $i down
iw dev $i set type ibss 
#ifconfig $1 20.20.0.$ID netmask 255.255.255.0 up
ifconfig $i 20.20.0.$ID
ifconfig $i netmask 255.255.255.0
ifconfig $i up
iw $i ibss join dronemesh-adhoc $2

#set up batman 
modprobe batman_adv 
batctl if add $i
ifconfig bat0 10.10.0.$ID netmask 255.255.255.0 up


rm /etc/quagga/zebra.conf

if [ ! -e "/etc/quagga/zebra.conf" ]
then
    echo "hostname dronemesh-ap-"$ID > /etc/quagga/zebra.conf
    echo "password zebra" >> /etc/quagga/zebra.conf
    echo "enable password zebra" >> /etc/quagga/zebra.conf
    echo "debug zebra events" >> /etc/quagga/zebra.conf
    echo "debug zebra packet" >> /etc/quagga/zebra.conf
    echo "ip forwarding" >> /etc/quagga/zebra.conf
    echo "log file /var/log/quagga/zebra.log" >> /etc/quagga/zebra.conf
fi

rm /etc/quagga/ripd.conf
if [ ! -e "/etc/quagga/ripd.conf" ]
then
    echo "hostname ripd" > /etc/quagga/ripd.conf
    echo "password zebra" >> /etc/quagga/ripd.conf
    echo "debug rip events" >> /etc/quagga/ripd.conf
    echo "debug rip packet" >> /etc/quagga/ripd.conf
    echo "router rip" >> /etc/quagga/ripd.conf
    echo "  version 2" >> /etc/quagga/ripd.conf
    echo "  network 10.10."$ID".0/24" >> /etc/quagga/ripd.conf
    echo "  network 10.10.0.0/24" >> /etc/quagga/ripd.conf
    echo "  passive-interface wlan3" >> /etc/quagga/ripd.conf
    echo "log file /var/log/quagga/ripd.log" >> /etc/quagga/ripd.conf
fi

#service ifplugd start
service quagga restart
ip link set up dev $i
ip link set up dev bat0
batctl nc 0
