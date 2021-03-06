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
echo "choise 2 to config drbd on all nodes."
echo "choise 3 to config ocfs-cluster on all nodes."
echo "choise 4 to mount ocfs share volume on all nodes."
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

ssh $node1 "yum -y install $dir/linux-firmware.rpm;rpm -ivh $dir/kernel.rpm"
ssh $node2 "yum -y install $dir/linux-firmware.rpm;rpm -ivh $dir/kernel.rpm"
echo "pls reboot each nodes to take effect new kernel."
;;

2)
read -p "pls input first node name: " node1
read -p "pls input second node name: " node2
read -p "pls input first node ip: " ip1
read -p "pls input second node ip: " ip2
read -p "pls input drbd device[/dev/vg1/lv1]: " dev

dir="/root/ocfs"
ssh $node1 "rpm -ivh $dir/drbd-utils.rpm;rpm -ivh $dir/kmod-drbd.rpm"
ssh $node2 "rpm -ivh $dir/drbd-utils.rpm;rpm -ivh $dir/kmod-drbd.rpm"

ssh $node1 "systemctl enable drbd;systemctl start drbd"
ssh $node2 "systemctl enable drbd;systemctl start drbd"

cat > /etc/drbd.d/global_common.conf << EOF
global {
  usage-count no;
}
common {
  net {
    protocol C;
  }
}
EOF

cat > /etc/drbd.d/drbd0.res << EOF
resource drbd0 {
net {
allow-two-primaries;
}
  disk $dev;
  device /dev/drbd0;
  meta-disk internal;
  on $node1 {
    address $ip1:7789;
  }
  on $node2 {
    address $ip2:7789;
  }
}
EOF

scp /etc/drbd.d/global_common.conf $node2:/etc/drbd.d/
scp /etc/drbd.d/drbd0.res $node2:/etc/drbd.d/

ssh $node1 "drbdadm create-md drbd0"
ssh $node2 "drbdadm create-md drbd0"

ssh $node1 "drbdadm up drbd0"
ssh $node2 "drbdadm up drbd0"

sleep 5
ssh $node1 "drbdadm primary drbd0 --force"
sleep 5
ssh $node2 "drbdadm primary drbd0"
sleep 5
drbdadm status drbd0
;;

3)
read -p "pls input first node name: " node1
read -p "pls input second node name: " node2
read -p "pls input first node ip: " ip1
read -p "pls input second node ip: " ip2

dir="/root/ocfs"

ssh $node1 "rpm -ivh $dir/ocfs2-tools.rpm"
ssh $node2 "rpm -ivh $dir/ocfs2-tools.rpm"

ssh $node1 "o2cb add-cluster c1;o2cb add-node c1 $node1 --ip $ip1;o2cb add-node c1 $node2 --ip $ip2"
ssh $node2 "o2cb add-cluster c1;o2cb add-node c1 $node1 --ip $ip1;o2cb add-node c1 $node2 --ip $ip2"

cat > /etc/sysconfig/o2cb << EOF
# O2CB_ENABLED: 'true' means to load the driver on boot.
O2CB_ENABLED=true

# O2CB_STACK: The name of the cluster stack backing O2CB.
O2CB_STACK=o2cb

# O2CB_BOOTCLUSTER: If not empty, the name of a cluster to start.
O2CB_BOOTCLUSTER=c1

# O2CB_HEARTBEAT_THRESHOLD: Iterations before a node is considered dead.
O2CB_HEARTBEAT_THRESHOLD=21

# O2CB_IDLE_TIMEOUT_MS: Time in ms before a network connection is considered dead.
O2CB_IDLE_TIMEOUT_MS=15000

# O2CB_KEEPALIVE_DELAY_MS: Max time in ms before a keepalive packet is sent
O2CB_KEEPALIVE_DELAY_MS=2000

# O2CB_RECONNECT_DELAY_MS: Min time in ms between connection attempts
O2CB_RECONNECT_DELAY_MS=2000
EOF

scp /etc/sysconfig/o2cb $node2:/etc/sysconfig/

ssh $node1 "systemctl enable o2cb;systemctl enable ocfs2;systemctl start o2cb"
ssh $node2 "systemctl enable o2cb;systemctl enable ocfs2;systemctl start o2cb"

o2cb list-cluster c1

ssh $node1 "o2cb register-cluster c1;o2cb cluster-status"
ssh $node2 "o2cb register-cluster c1;o2cb cluster-status"
;;

4)
read -p "pls input first node name: " node1
read -p "pls input second node name: " node2
read -p "pls input share volume [/dev/drbd0]: " vol
read -p "pls input mount point [/data]: " dir

ssh $node1 "mkdir $dir"
ssh $node2 "mkdir $dir"

mkfs.ocfs2 --cluster-size 8K -J size=32M -T mail \
  --node-slots 2 --label ocfs2_fs --mount cluster \
  --fs-feature-level=max-features \
  --cluster-stack=o2cb --cluster-name=c1 \
  $vol

ssh $node1 "echo '$vol $dir ocfs2 rw,_netdev 0 0' >> /etc/fstab"
ssh $node2 "echo '$vol $dir ocfs2 rw,_netdev 0 0' >> /etc/fstab"

ssh $node1 "mount -a"
ssh $node2 "mount -a"
mounted.ocfs2 -f
;;

*)
echo "pls input 1-4 choise."
exit;

esac
