pvcreate /dev/vdb
vgcreate vg1 /dev/vdb
lvcreate -n lv1 -L 5g vg1

cat >> /etc/rc.local << EOF
sleep 10
drbdadm primary drbd0
sleep 5
mount -a
EOF

chmod 755 /etc/rc.local

cat > /etc/exports << EOF
/nfs 192.168.6.0/24(rw,no_root_squash,async)
EOF
