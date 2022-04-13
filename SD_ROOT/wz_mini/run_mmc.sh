#!/bin/sh

set -x

##DO NOT ENABLE FW UPGRADE.  FW UPGRADE CAN POTENTIALLY CORRUPT THE KERNEL REQUIRING YOU  TO REFLASH THE STOCK FIRMWARE.
DISABLE_FW_UPGRADE="true"

HOSTNAME="WCV3_spare_test"
ENABLE_USB_ETH="false"
ENABLE_USB_DIRECT="false"

echo  "run_mmc.sh start" > /dev/kmsg

if [[ -d /configs/.ssh ]]; then
	echo "dropbear ssh config dir present"
else
	echo "dropbear ssh config dir not present, creating"
	mkdir /configs/.ssh
fi

if [[ "$ENABLE_USB_ETH" == "true" ]]; then
        ifconfig eth0 down
        ifconfig wlan0 down

        /media/mmc/wz_mini/bin/busybox  ip link set wlan0 name wlanold
        /media/mmc/wz_mini/bin/busybox  ip link set eth0 name wlan0

        ifconfig wlan0 up
        udhcpc -i wlan0
        /media/mmc/wz_mini/bin/dropbearmulti dropbear -R -m &
        sleep 5
        mount -o bind /media/mmc/wz_mini/bin/wpa_cli.sh /bin/wpa_cli
	else
	        echo "usb ethernet disabled"
fi


if [[ "$ENABLE_USB_DIRECT" == "true" ]]; then
#	if [[ ! -d /sys/class/net/usb0* ]]; then
	##ONLY WORKS WITH g_ethernet enabled kernel
        ifconfig usb0 down
        ifconfig wlan0 down
	/media/mmc/wz_mini/bin/busybox ip link set wlan0 address 02:01:02:03:04:08
        /media/mmc/wz_mini/bin/busybox ip link set wlan0 name wlanold
        /media/mmc/wz_mini/bin/busybox ip link set usb0 name wlan0

        ifconfig wlan0 up
        udhcpc -i wlan0
        /media/mmc/wz_mini/bin/dropbearmulti dropbear -R -m &
        sleep 5
        mount -o bind /media/mmc/wz_mini/bin/wpa_cli.sh /bin/wpa_cli
	else
		echo "usb direct disabled"
fi

if [[ "$DISABLE_FW_UPGRADE" == "true" ]]; then
	mkdir /tmp/Upgrade
	mount -t tmpfs -o size=1,nr_inodes=1 none /tmp/Upgrade
	echo -e "127.0.0.1 localhost \n127.0.0.1 wyze-upgrade-service.wyzecam.com" > /tmp/.hosts_wz
	mount --bind /tmp/.hosts_wz /etc/hosts
fi

echo set hostname
hostname $HOSTNAME

echo Run dropbear ssh server
/media/mmc/wz_mini/bin/dropbearmulti dropbear -R -m

sleep 3

#Place commands here to run 30 seconds after boot
#such as mount nfs, ping, etc

#mount -t nfs -o nolock,rw,noatime,nodiratime 192.168.1.1:/volume1 /media/mmc/record