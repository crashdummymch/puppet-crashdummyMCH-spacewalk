class spacewalk::client::packagemanager::suse(
	$spacewalk_packagemanager_enable	= 1,
	$spacewalk_packagemanager_gpgcheck	= 1,
	$spacewalk_packagemanager_removes	= undef,
)inherits spacewalk::client::packagemanager {

	Tidy['spacewalk_packagemanager_removes']{
		path	=> '/etc/zypp/repos.d',
		matches	=> $spacewalk_packagemanager_removes
	}
}
