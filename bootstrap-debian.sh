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

echo "debootstrap"
#sudo debootstrap --arch i386 lenny /opt/bootstrap-lenny http://ftp.uk.debian.org/debian/
#exit

# make sure there is no pre-exisitng directory
#if [ -d "/vz/private/$CTID" ] ; then
#	echo "/vz/private/$CTID already exists, exiting"
#	exit
#fi

cp -ra /opt/bootstrap-lenny/* /vz/private/$CTID/
#cp -a  /etc/vz/dists/debian-4.0.conf  /etc/vz/dists/debian-5.0.conf
echo "OSTEMPLATE=debian-5.0" >> /etc/vz/conf/$CTID.conf

vzctl set $CTID --applyconfig basic --save
vzctl set $CTID --ipadd 10.0.156.$CTID --save
vzctl set $CTID --nameserver "10.0.156.4 10.0.156.8" --save
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

