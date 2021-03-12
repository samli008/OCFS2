## ocfs2 on ubuntu 18.04
## dpkg -i ocfs2-tools.deb
```
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
echo "choise 1 to config ocfs-cluster on all nodes."
echo "choise 2 to mount ocfs share volume on all nodes."
read -p "pls input your choise [1]: " n

case $n in
1)
read -p "pls input first node name: " node1
read -p "pls input second node name: " node2
read -p "pls input first node ip: " ip1
read -p "pls input second node ip: " ip2

ssh $node1 "o2cb add-cluster c1;o2cb add-node c1 $node1 --ip $ip1;o2cb add-node c1 $node2 --ip $ip2"
ssh $node2 "o2cb add-cluster c1;o2cb add-node c1 $node1 --ip $ip1;o2cb add-node c1 $node2 --ip $ip2"

ssh $node1 "systemctl enable o2cb;systemctl enable ocfs2;systemctl start o2cb"
ssh $node2 "systemctl enable o2cb;systemctl enable ocfs2;systemctl start o2cb"

o2cb list-cluster c1

ssh $node1 "o2cb register-cluster c1;o2cb cluster-status"
ssh $node2 "o2cb register-cluster c1;o2cb cluster-status"
;;

2)
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
echo "pls input 1-2 choise."
exit;

esac
```
