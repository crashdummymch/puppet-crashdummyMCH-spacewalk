
class spacewalk::client::rhnsd (
	$enable											= true,
	$ensure											= 'running',
	$spacewalk_rhnsd_interval						= 240,

) inherits spacewalk::client {

	file { 'sysconfig_rhnsd':
		path    => '/etc/sysconfig/rhn/rhnsd',
		content => template("$module_name/client/rhnsd/rhnsd-template.erb"),
		ensure  => present,
	}
	service { 'rhnsd':
		name   => 'rhnsd',
		ensure => $ensure,
		enable => $enable,
	}
	cron {
		"spacewalk_rhn_check_cron":
		ensure => absent,
	}
}
