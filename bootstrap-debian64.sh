#!/bin/sh

VZROOT=/vz/private
VZCONFIG=basic

if [ $# -ne 2 ] ; then
	echo "$0 CTID hostname"
	exit 1
fi

validCTID() { echo "$1" | grep -q -w -E '^[0-9]+$' > /dev/null 2>&1 ; }

CTID="$1"
HOSTNAME="$2"

if ! validCTID "$CTID" ; then
	echo "Invalid CITD \"$CTID\""
	exit 1 
fi

if [ -d $VZROOT/$CTID ] ; then
	echo "Container $VZROOT/$CTID already exists."
	exit 1
fi

invalidHostname() { echo $1 | grep -q 'fen.aptivate.org' > /dev/null 2>&1 ; }

if invalidHostname "$HOSTNAME" ; then
	echo "Hostname $HOSTNAME contained 'fen.aptivate.org', only use the sub domain component"
	exit 1
fi

# http://download.openvz.org/template/precreated/centos-5-x86-devel.tar.gz
vzctl create $CTID --ostemplate debian-6.0-standard_6.0-x86_64 &&
vzctl set $CTID --applyconfig $VZCONFIG --save && 
vzctl set $CTID --ipadd 10.0.156.$CTID --save && 
vzctl set $CTID --nameserver "10.0.156.4 10.0.156.8" --save && 
vzctl set $CTID --hostname $HOSTNAME.fen.aptivate.org --save && 
vzctl set $CTID --diskspace 6G:8G --save && 
vzctl set $CTID --privvmpages 512M:1G --save && 
vzctl set $CTID --name $HOSTNAME --save &&
vzctl start $CTID --wait

#TODO: remove exit when puppet is sorted
exit

## post install
# need to get it configured quick - really cfengine/puppet job.
# follow the instructions at https://wiki.aptivate.org/Wiki.jsp?page=NetworkInfrastructure.Puppet

