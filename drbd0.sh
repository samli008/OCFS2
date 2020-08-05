systemctl enable drbd
systemctl start drbd

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
  disk /dev/vg1/lv1;
  device /dev/drbd0;
  meta-disk internal;
  on c03 {
    address 192.168.100.69:7789;
  }
  on c04 {
    address 192.168.100.70:7789;
  }
}
EOF

lsmod |grep drbd
