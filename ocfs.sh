#!/bin/bash
clear
echo
echo "-----The OCFS2 auto install with cli-------"
echo
echo "-----Make sure install node ssh trusted each nodes----------"
echo "-----Make sure each nodes in /etc/hosts configured---"
echo "-----Make sure /root/ocfs soft folder exist -------------"
echo
# ocfs cluster
echo "choise 1 to upgrade kernel on all nodes."
echo "choise 2 to install ocfs2-tools on all nodes."
echo "choise 3 to config ocfs-cluster on all nodes."
read -p "pls input your choise [1]: " n

case $n in
1)
if [ ! -d "/root/ocfs" ];then
	echo "sorry /root/ocfs software folder not exist installer exit !"
	exit 1
fi

read -p "pls input first node name: " node1
read -p "pls input second node name: " node2

dir="/root/ocfs"
scp -r $dir $node2:/root/

ssh $node1 "yum -y install $dir/linux-firmware.rpm;yum -y install $dir/kernel.rpm"
ssh $node2 "yum -y install $dir/linux-firmware.rpm;yum -y install $dir/kernel.rpm"
;;

*)
echo "pls input 1-3 choise."
exit;

esac
