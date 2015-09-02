class spacewalk::client::packagemanager::redhat(
	$spacewalk_packagemanager_enable	= 1,
	$spacewalk_packagemanager_gpgcheck	= 1,
	$spacewalk_packagemanager_removes	= undef,
)inherits spacewalk::client::packagemanager {

	file { 'yum_rhn_plugin_config':
		path	=> '/etc/yum/pluginconf.d/rhnplugin.conf',
		content	=> template("${module_name}/client/packagemanager/redhat/rhnplugin.conf-template.erb"),
	}

	Tidy['spacewalk_packagemanager_removes']{
		path	=> '/etc/yum.repos.d',
		matches	=> $spacewalk_packagemanager_removes
	}
}
