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

IFACES=$(awk '/vnet|face/ { next; } /e[n,t].*/ {print $1}' /proc/net/dev | grep -v FACE)
IFACE=$(echo ${IFACES} | sed 's/\://g' | head -1)

if [ ! -d /configdrive ]; then
    mkdir -p /configdrive
fi

if [ ! -b /dev/sr0 ]; then
    echo "ERROR no support for fake CD"
    exit 1
fi

mount /dev/sr0 /configdrive

mysudo=<<EOF
# User rules for clear
clear ALL=(ALL) NOPASSWD:AL
EOF
DSUDO=/etc/sudoers.d/
if [ ! -d ${DSUDO} ]; then
    mkdir -p ${DSUDO}
fi
echo ${mysudo} > ${DSUSO}/10-oscd.clear
cd ${WORKDIR}
cp oscd.service /usr/lib/systemd/system/
#systemctl enable oscd.service
${OSCD} --nics=${IFACE} --network=${NETWORK} --meta=${META}
cp hostname /etc/hostname
cp 60-oscd.network /etc/systemd/network/
user

#Cleaning up
umount /configdrive
rm -rf /configdrive