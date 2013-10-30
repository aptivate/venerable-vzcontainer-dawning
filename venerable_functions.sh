legacyNotice() {
	echo "THIS SCRIPT COULD BE OLD (and broken)"
	echo "The code for the bootstrap scripts resides in svn:"
	echo "https://svn.aptivate.org/svn/infrastructure/servers/fen-vzX/vz-bootstrap-scripts/"
	echo "If you improve this script please make sure to commit changes"
	echo "Also remember to copy changes to fen-vz3.fen"
}

validCTID() { echo "$1" | grep -q -w -E '^[0-9]+$' > /dev/null 2>&1 ; }
invalidHostname() { echo $1 | grep -q 'fen.aptivate.org' > /dev/null 2>&1 ; }

validateArgs() {
	if ! validCTID "$CTID" ; then
		echo "Invalid CITD \"$CTID\""
		exit 1
	fi

	if [ -d $VZROOT/$CTID ] ; then
		echo "Container $VZROOT/$CTID already exists."
		exit 1
	fi

	if invalidHostname "$HOSTNAME" ; then
		echo "Hostname $HOSTNAME contained 'fen.aptivate.org', only use the sub domain component"
		exit 1
	fi
}

openvz_version_customizations() {
	VZCREATE_EXTRA_ARGS=""
	VZSTART_EXTRA_ARGS=""
	OPENVZ_VERSION=$(vzctl --version | cut -d' ' -f3 | cut -d'.' -f1)

	case "$OPENVZ_VERSION" in
	3) # fen-vz2.fen
	;;
	4) # fen-vz3.fen
		VZCREATE_EXTRA_ARGS="--name ${HOSTNAME} --diskspace 6G:8G"
		VZSTART_EXTRA_ARGS="--wait"
	;;
	*)
		echo "unsupported vzctl version ${openvz_version}"
		exit 1
	;;
	esac
}

create_vzcontainer_from_template() {
	local ostemplate=$1

	vzctl create $CTID \
		--ostemplate $ostemplate \
		--config $VZCONFIG \
		--ipadd 10.0.156.$CTID \
		--hostname $HOSTNAME.fen.aptivate.org \
		$VZCREATE_EXTRA_ARGS
	vzctl set $CTID --name ${HOSTNAME} --save
	vzctl set $CTID --diskspace 6G:8G --save
	vzctl set $CTID --nameserver "10.0.156.4 10.0.156.8" --save
	vzctl set $CTID --privvmpages 512M:1G --save
}

start_vzcontainer() {
	vzctl start $CTID $VZSTART_EXTRA_ARGS

	if [ "$OPENVZ_VERSION" -eq "3" ] ; then
		# vzctl start --wait seems to have problems with centos runlevels
		# it fen-vz2. So, do a hard wait
		sleep 10
	fi
}

wire_puppet_for_os() {
	local osfamily=$1

	case $osfamily in
	CentOS)
		$VZ_EXEC2 yum update -y
		$VZ_EXEC2 wget -O /etc/yum.repos.d/aptivate.repo \
			http://lin-repo.aptivate.org/yum/centos/${OSRELEASE}/aptivate.repo
		$VZ_EXEC2 yum makecache
		$VZ_EXEC2 yum install -y puppet
		$VZ_EXEC2 yum update -y
		;;
	*)
		echo "unsupported os family $osfamily"
		exit 1
	esac
}

wakeup_puppet() {
	$VZ_EXEC2 wget -O /etc/puppet/puppet.conf \
		http://lin-repo.aptivate.org/bootstrap/puppet.conf
	$VZ_EXEC2 /usr/sbin/puppetd --test --server puppet.aptivate.org
}

postinstallNotes() {
	echo "to finish puppet provisioning"
	echo "follow the instructions at https://wiki.aptivate.org/Wiki.jsp?page=NetworkInfrastructure.Puppet"
}
