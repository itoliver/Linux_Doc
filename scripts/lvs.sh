#!/bin/bash
#lvs,nginx高可用集群部署
#
#DR:ip=172.17.11.1 物理ip
#DR:vip=172.17.11.11 虚拟ip
#realserver1:172.17.11.213 物理ip
#realserver2:172.17.11.214 物理ip

#安装之前最好禁用seliux和iptables防火墙
systemctl stop firewalld
systemctc disable firewalld
sed -i 's#SELINUX=enforcing#SELINUX=disabled#' /etc/selinux/config
setenforce 0

#####start install nginx######
echo '######start install nginx######'

[ ！-d /software ] && mkdir -p /software

useradd www -s /sbin/nologin
yum -y groupinstall "Development Tools"
yum -y install pcre pcre-devel zlib zlib-devel gcc-c++ gcc openssl*

cd /software && wget http://nginx.org/download/nginx-1.13.8.tar.gz
tar zxvf nginx-1.12.0.tar.gz 

cd nginx-1.12.0/
./configure --user=www --group=www --prefix=/usr/local/nginx --with-http_realip_module --with-http_sub_module --with-http_gzip_static_module --with-http_stub_status_module  --with-pcre
make && make install
sleep 2
ln -s /usr/local/nginx/sbin/nginx /sbin/nginx

cat >> /usr/lib/systemd/system/nginx.service << EOF
[Unit]
Description=nginx - high performance web server
Documentation=http://nginx.org/en/docs/
After=network-online.target remote-fs.target nss-lookup.target
 
[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/sbin/nginx -t
ExecStart=/usr/sbin/nginx
ExecReload=//usr/sbin/nginx -s reload
ExecStop=/usr/sbin/nginx -s stop
PrivateTmp=true
 
[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload 
systemctl start nginx
systemctl enable nginx
systemctl status nginx
sleep 2
echo '######nginx is install completed done.######'

#install ipvsadm (centos7 yum源自带软件,也可以用源码编译安装)
#---------Director(DR)-----------
yum install -y ipvsadm

#Configura virtual nat script
cat >> /etc/init.d/lvs_nat << EOF
#! /bin/bash
#
# Starts the LVS virtual server daemon
#
# chkconfig: - 90 10

# Source function library.
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

echo 1 > /proc/sys/net/ipv4/ip_forward
ipv=/sbin/ipvsadm
vip=172.17.11.11
rs1=172.17.11.213
rs2=172.17.11.214
ifconfig eth0:0 down
ifconfig eth0:0 $vip broadcast $vip netmask 255.255.255.255 up
route add -host $vip dev eth0:0
$ipv -C
$ipv -A -t $vip:80 -s wrr
$ipv -a -t $vip:80 -r $rs1:80 -g -w 3
$ipv -a -t $vip:80 -r $rs2:80 -g -w 3
EOF

chmod a+x /etc/init.d/lvs_nat
chkconfig --add lvs_nat
chkconfig lvs_nat on
/etc/init.d/lvs_nat

#--------rs-1----------------
#install nginx
#参考上面安装
#配置realserver script
cat >> /etc/init.d/realserver << EOF
#!/bin/bash
#
# Starts the LVS real server daemon
#
# chkconfig: - 95 10

# Source function library.
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

VIP=172.17.11.11
case "$1" in
        start)
        ifconfig lo:0 $VIP netmask 255.255.255.255 broadcast $VIP
        /sbin/route add -host $VIP dev lo:0
        echo "1" > /proc/sys/net/ipv4/conf/lo/arp_ignore
        echo "2" > /proc/sys/net/ipv4/conf/lo/arp_announce
        echo "1" > /proc/sys/net/ipv4/conf/all/arp_ignore
        echo "2" > /proc/sys/net/ipv4/conf/all/arp_announce
        action "Realserver start" /bin/true
        ;;

        stop)
        ifconfig lo:0 down
        route del $VIP > /dev/null 2>&1
        echo "0" > /proc/sys/net/ipv4/conf/lo/arp_ignore
        echo "0" > /proc/sys/net/ipv4/conf/lo/arp_announce
        echo "0" > /proc/sys/net/ipv4/conf/all/arp_ignore
        echo "0" > /proc/sys/net/ipv4/conf/all/arp_announce
        action "Realserver stoped" bin/true
        ;;

        restart)
        stop
        sleep 2
        start
        ;;

        *)
        echo "Usage: $0 {start|stop|restart}"
        exit 1
esac
exit 0
EOF
chmod a+x /etc/init.d/realserver
chkconfig --all realserver
chkconfig realserver on
/etc/init.d/realserver start
