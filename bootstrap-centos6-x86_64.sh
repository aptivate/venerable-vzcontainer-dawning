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

# http://download.openvz.org/template/precreated/centos-6-x86_64-devel.tar.gz
vzctl create $CTID --ostemplate centos-6-x86_64-devel &&
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

if [ $? -eq 0 ] ; then
	# install puppet and do first run
	vzctl exec2 $CTID wget -O /etc/yum.repos.d/aptivate.repo http://lin-repo.aptivate.org/yum/centos/5/aptivate.repo &&
	#vzctl exec2 $CTID rpm -Uvh http://download.fedora.redhat.com/pub/epel/5/i386/epel-release-5-4.noarch.rpm &&
	vzctl exec2 $CTID yum install -y puppet &&
	vzctl exec2 $CTID /usr/sbin/puppetd --test --server puppet.aptivate.org
	vzctl exec2 $CTID yum update -y
fi

exit

## post install
# need to get it configured quick - really cfengine/puppet job.
# follow the instructions at https://wiki.aptivate.org/Wiki.jsp?page=NetworkInfrastructure.Puppet

