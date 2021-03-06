#!/bin/bash
# ************************************************
# Openstack ConfigDrive for ClearLinux
# (C) 2019 Intel Corporation
# Fabian Salamanca fabian.salamanca@intel.com
# ************************************************

user() {
    useradd -m -d /home/clear clear
    mkdir -p /home/clear/.ssh
    cp authorized_keys /home/clear/.ssh/
    chmod 0600 /home/clear/.ssh/authorized_keys
    chown -R clear /home/clear/.ssh
}

WORKDIR=/usr/local/oscd
OSCD=${WORKDIR}/oscd
NETWORK=/configdrive/openstack/latest/network_data.json
META=/configdrive/openstack/latest/meta_data.json
UDATA=/configdrive/openstack/latest/user_data

sleep 5 # Wait for parallelized systemd tasks to bring necessary devices

if [ ! -d /configdrive ]; then
    mkdir -p /configdrive
fi

if [ ! -b /dev/sr0 ]; then
    sleep 2
    if [ ! -b /dev/sr0 ]; then
        echo "ERROR no support for fake CD"
        exit 1
    fi
fi

echo "Attempting to read from ConfigDrive"
mount /dev/sr0 /configdrive

IFACES=$(awk '/vnet|face/ { next; } /e[n,t].*/ {print $1}' /proc/net/dev | grep -v FACE)
IFACE=$(echo ${IFACES} | sed 's/\://g' | head -1)

mysudo1="clear ALL=(ALL) NOPASSWD:ALL"
mysudo2="root ALL=(ALL) NOPASSWD:ALL"
DSUDO=/etc/sudoers.d/
if [ ! -d ${DSUDO} ]; then
    mkdir -p ${DSUDO}
fi
echo ${mysudo1} > ${DSUDO}/10-oscd-user
echo ${mysudo2} >> ${DSUDO}/10-oscd-user
cd ${WORKDIR}
cp oscd.service /usr/lib/systemd/system/
#systemctl enable oscd.service
${OSCD} --nics=${IFACE} --network=${NETWORK} --meta=${META}
cp hostname /etc/hostname
if [ ! -d /etc/systemd/network ]; then
    mkdir -p /etc/systemd/network
fi
cp 60-oscd.network /etc/systemd/network/
user

# User data
echo
echo "Reading user_data if found"
if [ -f ${UDATA} ]; then
    echo ""
    echo "Found user_data"
    echo "---------------"
    echo ""
    cp ${UDATA} /tmp
    chmod 0755 /tmp/user_data
    bash /tmp/user_data
fi

#Cleaning up
umount /configdrive
rm -rf /configdrive

systemctl restart systemd-networkd.service
hostname $(cat /etc/hostname)

echo "Attempting to grow root fs"
rootfs=$(mount | awk '/on \/ / {print $1}')
disk=$(echo ${rootfs} | tr -d "[0-9]")
partnumb=$(echo ${rootfs} | tr -cd "[:digit:]")
chmod 0755 /usr/local/oscd/growpart
/usr/local/oscd/growpart ${disk} ${partnumb}
resize2fs ${rootfs}

