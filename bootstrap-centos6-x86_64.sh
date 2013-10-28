#!/bin/sh

VZROOT=/vz/private
VZCONFIG=basic
DAWNING_PLACE=/usr/local/sbin
OSFAMILY="CentOS"
OSRELEASE="6"

. ${DAWNING_PLACE}/venerable_functions.sh

chekNumberOfArgs

CTID="$1"
HOSTNAME="$2"

validateArgs

# http://download.openvz.org/template/precreated/centos-6-x86_64-devel.tar.gz
set -e
create_vzcontainer_from_template "centos-6-x86_64-devel"
vzctl start $CTID --wait

if [ $? -eq 0 ] ; then
	wire_puppet_for_os $OSFAMILY
	wakeup_puppet
fi

exit

postinstallNotes


