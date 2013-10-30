#!/bin/sh

VZROOT=/vz/private
VZCONFIG=basic
DAWNING_PLACE=/usr/local/sbin
OSFAMILY="CentOS"
OSRELEASE="6"

. ${DAWNING_PLACE}/venerable_functions.sh

if [ $# -ne 2 ] ; then
	echo "Usage: $0 CTID hostname"
	exit 1
fi

CTID="$1"
HOSTNAME="$2"

validateArgs

VZ_EXEC2="vzctl exec2 $CTID"

# http://download.openvz.org/template/precreated/centos-5-x86-devel.tar.gz
set -e
openvz_version_customizations
create_vzcontainer_from_template "centos-6-standard_6.3-1_i386"
start_vzcontainer

if [ $? -eq 0 ] ; then
	wire_puppet_for_os $OSFAMILY
	wakeup_puppet
fi

postinstallNotes
