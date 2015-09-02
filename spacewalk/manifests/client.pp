
class spacewalk::client (
	$spacewalk_server								,
	$spacewalk_activationkey						,
	$rhns_ca_cert,
	$spacewalk_profilename 							= $fqdn,
	$spacewalk_proto 								= 'http',
	$spacewalk_regforce 							= false,
	$spacewalk_action								= false,
	$spacewalk_action_deploy 						= false,
	$spacewalk_action_diff 							= false,
	$spacewalk_action_upload						= false,
	$spacewalk_action_mtime							= false,
	$spacewalk_action_run							= false,
	$spacewalk_up2date_tmpDir 						= '/tmp',
	$spacewalk_up2date_skipNetwork 					= 0,
	$spacewalk_up2date_stagingContent 				= 1,
	$spacewalk_up2date_networkRetries 				= 1,
	$spacewalk_up2date_enableProxy 					= 0,
	$spacewalk_up2date_writeChangesToLog 			= 0,
	$spacewalk_up2date_proxyPassword 				= '',
	$spacewalk_up2date_proxyUser 					= '',
	$spacewalk_up2date_httpProxy 					= '',
	$spacewalk_up2date_enableProxyAuth 				= 0,
	$spacewalk_up2date_stagingContentWindow 		= 24,
	$spacewalk_up2date_noReboot 					= 0,
	$spacewalk_up2date_path 						= '/etc/sysconfig/rhn/up2date',
	$spacewalkc_systemid_path 						= '/etc/sysconfig/rhn/systemid'
) inherits spacewalk {

	#####variables==start#####
	$spacewalk_up2date_serverUrl	="${spacewalk_proto}://${spacewalk_server}/XMLRPC"
	$spacewalk_rhn_actions_control	="/usr/bin/rhn-actions-control "
	$action_deploy = $spacewalk_action_deploy ?{
		true	=> '--enable-deploy',
		false	=> '--disable-deploy',
	}
	$report_deploy = $spacewalk_action_deploy ?{
		true	=> 'enabled',
		false	=> 'disabled',
	}
	$action_diff = $spacewalk_action_diff ?{
		true	=> '--enable-diff',
		false	=> '--disable-diff',
	}
	$report_diff = $spacewalk_action_diff ?{
		true	=> 'enabled',
		false	=> 'disabled',
	}
	$action_upload = $spacewalk_action_upload ?{
		true	=> '--enable-upload',
		false	=> '--disable-upload',
	}
	$report_upload = $spacewalk_action_upload ?{
		true	=> 'enabled',
		false	=> 'disabled',
	}
	$action_mtime = $spacewalk_action_mtime ?{
		true	=> '--enable-mtime',
		false	=> '--disable-mtime',
	}
	$report_mtime = $spacewalk_action_mtime ?{
		true	=> 'enabled',
		false	=> 'disabled',
	}
	$action_run = $spacewalk_action_run ?{
		true	=> '--enable-run',
		false	=> '--disable-run',
	}
	$report_run = $spacewalk_action_run ?{
		true	=> 'enabled',
		false	=> 'disabled',
	}
	#####variables==end#####

	#####package==start#####
	package { 'rhncfg':
		ensure	=> installed,
	}
	package { 'rhncfg-actions':
		ensure	=> installed,
	}
	package { 'rhncfg-client':
		ensure	=> installed,
	}
	package { 'rhncfg-management':
		ensure	=> installed,
	}
	package { 'rhn-check':
		ensure	=> installed,
	}
	package { 'rhn-client-tools':
		ensure	=> installed,
	}
	package { 'rhnlib':
		ensure	=> installed,
	}
	package { 'rhnsd':
		ensure	=> installed,
	}
	package { 'rhn-setup':
		ensure	=> installed,
	}
	$spacewalk_packagemanager_name = $::osfamily?{
		'redhat'	=> 'yum-rhn-plugin',
		'suse'		=> 'zypp-plugin-spacewalk',
	}
	package { 'spacewalk_packagemanager':
		ensure	=> installed,
		name	=> $spacewalk_packagemanager_name
	}
	#####package==end#####


	#Register system with spacewalk only if
	#rhn_check shows system is not registered
	$rhn_registration_command_base ="rhnreg_ks --serverUrl=${spacewalk_up2date_serverUrl} --activationkey=${spacewalk_activationkey} --profilename=${spacewalk_profilename} "
	if $spacewalk_regforce == true {
		$rhn_registration_command = "${rhn_registration_command_base} --force "
	}
	else {
		$rhn_registration_command = "${rhn_registration_command_base}"
	}

	file { 'RHNS_CA_CERT' :
		path    => '/usr/share/rhn/RHNS-CA-CERT',
		content => $rhns_ca_cert,
		owner   => "root",
		group   => "root",
		mode    => 0644,
		notify  => Exec['rhn-profile-sync'],
	}


	file { 'rhn_up2date_configuration':
		path		=> $spacewalk_up2date_path,
		content		=> template("$module_name/client/up2date-template.erb"),
		ensure		=> present,
		notify		=> Exec['rhn-profile-sync'],
	}

	exec { 'rhn_check_registration':
		command		=> "rm -f ${spacewalkc_systemid_path}; ${rhn_registration_command}",
		#onlyif		=> "test `/usr/sbin/rhn-profile-sync > /dev/null 2>&1; echo $?` -ne 0 -a `ping -c 1 ${spacewalk_server}  > /dev/null 2>&1; echo $?` -eq 0",
		creates     => '/etc/sysconfig/rhn/systemid',
		logoutput	=> true,
		require     => [ File['rhn_up2date_configuration'], File['RHNS_CA_CERT'] ],
	}


	exec { 'rhn-profile-sync':
		command		=> "rhn-profile-sync",
		refreshonly	=> true,
		logoutput	=> true,
	}

	#####rhn_actions ==start#####
	#only work with actions if $spacewalk_action is set to true
	if $spacewalk_action {
		exec { 'rhn_actions_deploy':
			command		=> "${spacewalk_rhn_actions_control} ${action_deploy}",
			onlyif		=> "test `${spacewalk_rhn_actions_control} --report | grep deploy | awk '{print \$3}'` != ${report_deploy}",
			logoutput	=> true,
			require		=> Exec['rhn_check_registration'],
		}
		exec { 'rhn_actions_diff':
			command		=> "${spacewalk_rhn_actions_control} ${action_diff}",
			onlyif		=> "test `${spacewalk_rhn_actions_control} --report | grep diff | awk '{print \$3}'` != ${report_diff}",
			logoutput	=> true,
			require		=> Exec['rhn_check_registration'],
		}
		exec { 'rhn_actions_upload':
			command		=> "${spacewalk_rhn_actions_control} ${action_upload}",
			onlyif		=> "test `${spacewalk_rhn_actions_control} --report | grep upload | awk '{print \$3}'` != ${report_upload}",
			logoutput	=> true,
			require		=> Exec['rhn_check_registration'],
		}
		exec { 'rhn_actions_mtime':
			command		=> "${spacewalk_rhn_actions_control} ${action_mtime}",
			onlyif		=> "test `${spacewalk_rhn_actions_control} --report | grep mtime | awk '{print \$3}'` != ${report_mtime}",
			logoutput	=> true,
			require		=> Exec['rhn_check_registration'],
		}
		exec { 'rhn_actions_run':
			command		=> "${spacewalk_rhn_actions_control} ${action_run}",
			onlyif		=> "test `${spacewalk_rhn_actions_control} --report | grep run | awk '{print \$3}'` != ${report_run}",
			logoutput	=> true,
			require		=> Exec['rhn_check_registration'],
		}
	}
	#####rhn_actions ==end#####

	
}
