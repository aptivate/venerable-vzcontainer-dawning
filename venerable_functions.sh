
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

create_vzcontainer_from_template() {
	local ostemplate=$1

	vzctl create $CTID \
		--ostemplate $ostemplate \
		--config $VZCONFIG \
		--ipadd 10.0.156.$CTID \
		--hostname $HOSTNAME.fen.aptivate.org \
		--diskspace 6G:8G \
		--name $HOSTNAME &&
	vzctl set $CTID --nameserver "10.0.156.4 10.0.156.8" --save &&
	vzctl set $CTID --privvmpages 512M:1G --save
}

wire_puppet_for_os() {
	local osfamily=$1

	case $osfamily in
	CentOS)
		$VZ_EXEC2 wget -O /etc/yum.repos.d/aptivate.repo \
			http://lin-repo.aptivate.org/yum/centos/${OSRELEASE}/aptivate.repo
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
