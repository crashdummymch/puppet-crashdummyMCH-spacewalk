#
#
#  Built specifically for CentOS (may work on SLES, but double checking may be prudent)

class spacewalk::proxy (
	$proxy_rhn_parent,
	$username,
	$password,
	$proxy_version,
	$proxy_ssl_org,
	$proxy_ssl_orgunit,
	$proxy_ssl_city,
	$proxy_ssl_state,
	$proxy_ssl_country,
	$ssl_build_openssl_template_path,
	$ssl_build_private_ssl_key_template_path,
	$ssl_build_trusted_ssl_cert_template_path,
	$proxy_use_ssl                    = 1,
	$proxy_ssl_password               = "",
	$proxy_ssl_email                  = "",
	$proxy_ssl_cname                  = "",
	$proxy_ssl_common                 = "${::fqdn}",
	$proxy_start_services             = 1,
	$proxy_install_monitoring         = 1,
	$proxy_enable_scout               = 0,
	$proxy_populate_config_channel    = 0,
	$proxy_monitoring_parent          = "",
	$proxy_monitoring_parent_ip       = "",
	$proxy_traceback_mail             = "",
	$apache_user                      = "apache",
	$apache_group                     = "apache",
	$proxy_ca_chain                   = '/usr/share/rhn/RHN-ORG-TRUSTED-SSL-CERT',
	$proxy_http_proxy                 = "",
	$proxy_http_proxy_username        = "",
	$proxy_http_proxy_password        = "",
	$proxy_proxy_local_flist          = "",
	$proxy_pkg_dir                    = "/var/spool/rhn-proxy",
	$proxy_distrotrees_dir            = "/var/www/html/pub/distro-trees/",
	$answer_file                      = "/root/spacewalk-proxy-default-answers",
	$install_script                   = "/root/install-proxy.sh",
	$sync_script                      = "/usr/local/sbin/spacewalk-sync.sh",
	$ssl_build_dir                    = "/root/ssl-build",
	$install_proxy_timeout            = 900,
	$squid_template_path              = "spacewalk/proxy/squid.conf.erb",

) inherits spacewalk {
	##################################################################################################
	# PACKAGE DEFS
	##################################################################################################
	$spacewalk_pkgs = [ 
		'spacewalk-backend',
		'spacewalk-backend-libs',
		'spacewalk-base-minimal',
		'spacewalk-certs-tools',
		'spacewalk-monitoring-selinux',
		'spacewalk-proxy-broker',
		'spacewalk-proxy-common',
		'spacewalk-proxy-docs',
		'spacewalk-proxy-html',
		'spacewalk-proxy-installer',
		'spacewalk-proxy-management',
		'spacewalk-proxy-monitoring',
		'spacewalk-proxy-package-manager',
		'spacewalk-proxy-redirect',
		'spacewalk-proxy-selinux',
		'spacewalk-setup-jabberd',
		'spacewalk-ssl-cert-check',
		'squid',
		'httpd',
	]

	# ensure they're installed
	package { [ $spacewalk_pkgs ] : ensure => installed }
	if !defined(Class['expect']) {
		class { 'expect': }
	}

	##################################################################################################
	# FILES / DIRECTORIES
	##################################################################################################
	# install proxy script
	file { "$install_script":
		content => template("spacewalk/proxy/spacewalk-proxy-install.sh.erb"),
		owner   => "root",
		group   => "root",
		mode    => 0744,
		require => [Package[$spacewalk_pkgs], Class['expect']]
	}
	# answer file
	file { "$answer_file":
		content => template("spacewalk/proxy/spacewalk-proxy-default-answers.erb"),
		owner   => "root",
		group   => "root",
		mode    => 0600,
		require => [Package[$spacewalk_pkgs]]
	}
	# ssl directory, will hold certs
	file { "$ssl_build_dir":
		ensure => "directory",
		owner  => "root",
		group  => "root",
		mode   => 0755,
		require => [Package[$spacewalk_pkgs]]
	}
	# ssl conf file 
	file { "$ssl_build_dir/rhn-ca-openssl.cnf":
		content => template("$ssl_build_openssl_template_path"),
		owner   => "root",
		group   => "root",
		mode    => 0400,
		require => [Package[$spacewalk_pkgs], File["$ssl_build_dir"]]
	}

	# ssl certs
	file { "$ssl_build_dir/RHN-ORG-PRIVATE-SSL-KEY":
		content => template("$ssl_build_private_ssl_key_template_path"),
		owner   => "root",
		group   => "root",
		mode    => 0400,
		require => [Package[$spacewalk_pkgs], File["$ssl_build_dir"]],
	}
	# note - creating/managing cert in two places per documented process
	file { ["$ssl_build_dir/RHN-ORG-TRUSTED-SSL-CERT","$proxy_ca_chain"] :
		content => template("$ssl_build_trusted_ssl_cert_template_path"),
		owner   => "root",
		group   => "root",
		mode    => 0644,
		require => [Package[$spacewalk_pkgs], File["$ssl_build_dir"]]
	}
	#
	file { "/etc/squid/squid.conf":
		content => template($squid_template_path),
		owner   => "root",
		group   => "root",
		mode    => 0400,
		require => Package[$spacewalk_pkgs]
	}
	file { "/etc/rhn/rhn.conf":
		content => template("spacewalk/proxy/spacewalk-proxy-default-rhn.conf.erb"),
		path    => "/etc/rhn/rhn.conf",
		owner   => "root",
		group   => "$apache_group",
		mode    => 0755,
		require => [ Package[$spacewalk_pkgs], Exec['spacewalk_proxy_install_proxy_sh']],
	}

	#required due Bug 1172738 spacewalk-proxy 2.2
	file { "/usr/share/rhn/proxy/broker/rhnRepository.py":
		content => template("$module_name/proxy/rhnRepository.py"),
		require => [ Package[$spacewalk_pkgs], Exec['spacewalk_proxy_install_proxy_sh'], ],
	}
		



	##################################################################################################
		# EXEC 
		##################################################################################################
	exec { "spacewalk_proxy_install_proxy_sh":
		logoutput => true,
		command   => "${install_script} '${username}' '${password}' > /var/log/spacewalk-proxy-install 2>&1",
		timeout   => "${install_proxy_timeout}",
		require   => [ 
			Package[$spacewalk_pkgs],
			File["$install_script"],
			File["$answer_file"],
			File["$ssl_build_dir"],
			File["$ssl_build_dir/rhn-ca-openssl.cnf"],
			File["$ssl_build_dir/RHN-ORG-PRIVATE-SSL-KEY"],
			File["$ssl_build_dir/RHN-ORG-TRUSTED-SSL-CERT"],
		],
		unless    => 'test -s /etc/rhn/rhn.conf',
	}
	##################################################################################################
	# SERVICE DEFS
	##################################################################################################

	service { "rhn-proxy":
		provider => "base",
		binary => "/usr/sbin/rhn-proxy",
		ensure => running,
		hasrestart => true,
		hasstatus => true,
		status => "/usr/sbin/rhn-proxy status",
		start => "/usr/sbin/rhn-proxy start",
		stop => "/usr/sbin/rhn-proxy stop",
		restart => "/usr/sbin/rhn-proxy restart",
		subscribe => [ File["/etc/rhn/rhn.conf"], File["/etc/squid/squid.conf"] ],
	}
}
