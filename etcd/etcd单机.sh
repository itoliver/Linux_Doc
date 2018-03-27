#搭建单机etcd
#安装etcd可以通过源码编译安装，也可以用yum安装，这里实验用yum安装
#Configure epel yum
wget http://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm && rpm -ivh epel-release-latest-7.noarch.rpm

#install etcd
yum install -y etcd

#Configure the etcd file
sed -i s#/ETCD_LISTEN_CLIENT_URLS="http://localhost:2379"/#/ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"/#g /etc/etcd/etcd.conf
sed -i s#/ETCD_ADVERTISE_CLIENT_URLS="http://localhost:2379"/#/ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"/#g /etc/etcd/etc.conf

systemctl enable etcd
systemctl restart etcd
systemctl status etcd
