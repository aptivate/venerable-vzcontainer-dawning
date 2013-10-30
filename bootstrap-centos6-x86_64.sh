#!/bin/sh

VZROOT=/vz/private
VZCONFIG=basic
DAWNING_PLACE=/usr/local/sbin
OSFAMILY="CentOS"
OSRELEASE="6"

. ${DAWNING_PLACE}/venerable_functions.sh

if hostname | grep fen-vz2 ; then
	echo "bootstrap-centos6-x86_64 is known to be broken on fen-vz2"
	echo "edit the script if you want to test"
	exit 1
fi

chekNumberOfArgs

CTID="$1"
HOSTNAME="$2"

validateArgs

VZ_EXEC2="vzctl exec2 $CTID"

# http://download.openvz.org/template/precreated/centos-6-x86_64-devel.tar.gz
set -e
openvz_version_customizations
create_vzcontainer_from_template "centos-6-x86_64-devel"
start_vzcontainer

if [ $? -eq 0 ] ; then
	wire_puppet_for_os $OSFAMILY
	wakeup_puppet
fi

exit

postinstallNotes


