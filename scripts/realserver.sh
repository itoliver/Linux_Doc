#add for chkconfig  
#chkconfig: 2345 70 30  #234都是文本界面，5就是图形界面X，70启动顺序号，30系统关闭，脚本  
#止顺序号  
#description: RealServer's script  #关于脚本的简短描述  
#processname: realserver.sh       #第一个进程名，后边设置自动时会用到  
#!/bin/bash  
VIP=172.17.11.186
source /etc/rc.d/init.d/functions
case "$1" in
start)
       ifconfig lo:0 $VIP netmask 255.255.255.255 broadcast $VIP
       /sbin/route add -host $VIP dev lo:0
       echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
       echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
       echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
       echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
       echo "RealServer Start OK"
       ;;
stop)
       ifconfig lo:0 down
       route del $VIP >/dev/null 2>&1
       echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
       echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
       echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
       echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
       echo "RealServer Stoped"
       ;;
       *)
       echo "Usage: $0 {start|stop}"
       exit 1
esac
exit 0