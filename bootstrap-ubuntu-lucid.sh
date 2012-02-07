#!/bin/sh

VZROOT=/vz/private

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

invalidHostname() { echo $1 | grep -q 'fen.aptivate.org' > /dev/null 2>&1 ; }

if invalidHostname "$HOSTNAME" ; then
	echo "Hostname $HOSTNAME contained 'fen.aptivate.org', only use the sub domain component"
	exit 1
fi

vzctl create $CTID --ostemplate ubuntu-10.04-x86
vzctl set $CTID --applyconfig vps.basic --save
vzctl set $CTID --ipadd 10.0.156.$CTID --save
vzctl set $CTID --nameserver 10.0.156.4 --save
vzctl set $CTID --hostname $HOSTNAME.fen.aptivate.org --save
vzctl set $CTID --diskspace 6G:8G --save
vzctl set $CTID --privvmpages 512M:1G --save
vzctl set $CTID --name $HOSTNAME --save
vzctl start $CTID

# install puppet and do first run
vzctl exec2 $CTID apt-get -y update
vzctl exec2 $CTID apt-get install -y puppet
vzctl exec2 $CTID /usr/sbin/puppetd --test --server puppet.aptivate.org
exit

## post install
# need to get it configured quick - really cfengine/puppet job.
# follow the instructions at https://wiki.aptivate.org/Wiki.jsp?page=NetworkInfrastructure.Puppet

