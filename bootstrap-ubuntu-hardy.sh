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

CTROOT="$VZROOT/$CTID"

if ! [ -d "$CTROOT" ] ; then
	mkdir "$CTROOT" > /dev/null 2>&1 \
	|| ( echo "Failed to mkdir \"$CTROOT\"" ; exit 1)
else 
	echo "Already exists \"$CTROOT\""
fi

if ! [ -d /opt/bootstrap-hardy ] ; then 
	echo "Running debootstrap"
	sudo debootstrap --arch i386 hardy /opt/bootstrap-hardy 
fi

# make sure there is no pre-exisitng directory
#if [ -d "/vz/private/$CTID" ] ; then
#	echo "/vz/private/$CTID already exists, exiting"
#	exit
#fi

cp -ra /opt/bootstrap-hardy/* /vz/private/$CTID/
cp -a  /etc/vz/dists/ubuntu.conf  /etc/vz/dists/ubuntu-8.04.conf
echo "OSTEMPLATE=ubuntu-8.04" >> /etc/vz/conf/$CTID.conf

vzctl set $CTID --applyconfig vps.basic --save
vzctl set $CTID --ipadd 10.0.156.$CTID --save
vzctl set $CTID --nameserver 10.0.156.4 --save
vzctl set $CTID --hostname $HOSTNAME.fen.aptivate.org --save
vzctl start $CTID --wait

# install puppet and do first run
vzctl exec2 $CTID apt-get -y update
vzctl exec2 $CTID apt-get install -y puppet
vzctl exec2 $CTID /usr/sbin/puppetd --test --server puppet.aptivate.org
exit

## post install
# need to get it configured quick - really cfengine/puppet job.
# follow the instructions at https://wiki.aptivate.org/Wiki.jsp?page=NetworkInfrastructure.Puppet

