#! /bin/bash
#
# Starts the LVS real server daemon
#
# chkconfig: - 90 10

# Source function library.
[ -f /etc/init.d/functions ] && . /etc/init.d/functions

echo 1 > /proc/sys/net/ipv4/ip_forward
ipv=/sbin/ipvsadm
vip=172.17.11.187
rs1=172.17.10.213
rs2=172.17.11.64
logger $0 called with $1

case "$1" in
	start)
	ifconfig eth0:0 down
	ifconfig eth0:0 $vip broadcast $vip netmask 255.255.255.255 up
	route add -host $vip dev eth0:0
	$ipv -C
	$ipv -A -t $vip:80 -s wrr -p 120
	#$ipv -A -t $vip:8080 -s wrr
	$ipv -a -t $vip:80 -r $rs1:80 -g -w 3
	$ipv -a -t $vip:80 -r $rs2:80 -g -w 3
	#$ipv -a -t $vip:80 -r $rs2:8080 -g -w 3
	touch /var/lock/subsys/ipvsadm > /dev/null 2>&1
	action "ipvsadm start" /bin/true
	;;

	stop)
	/sbin/ipvsadm -C
	/sbin/ipvsadm -Z
	ifconfig eth0:0 dowm
	route del $ipv
	rm -rf /var/lock/subsys/ipvsadm > /dev/null 2>&1
	action "ipvsadm stoped" /bin/true
	;;

	status)
	if [ ! -e /var/lock/subsys/ipvsadm ];then
	    echo "ipvsadm stoped"
	    exit 1
	else
	    echo "ipvsadm OK"
	fi
	;;

	*)
	echo "Usage: $0 {start|stop|status}"
	exit 1
esac
exit 0
