#!/bin/bash
WANTS=/etc/systemd/system/multi-user.target.wants
if [ ! -d ${WANTS} ]; then
	mkdir -p ${WANTS}
fi
cd /etc/systemd/system/multi-user.target.wants && ln -s /usr/lib/systemd/system/oscd.service 
