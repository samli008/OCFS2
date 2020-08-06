read -p "pls input first node name: " node1
read -p "pls input second node name: " node2
read -p "pls input first node ip: " ip1
read -p "pls input second node ip: " ip2
read -p "pls input drbd device[/dev/vg1/lv1]: " dev

ssh $node1 "rpm -ivh /root/ocfs/drbd-utils.rpm"
ssh $node2 "rpm -ivh /root/ocfs/drbd-utils.rpm"

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

ssh $node1 "drbdadm primary drbd0 --force"
ssh $node2 "drbdadm primary drbd0"

drbdadm status drbd0
