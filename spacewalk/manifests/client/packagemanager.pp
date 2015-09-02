class spacewalk::client::packagemanager(
	$spacewalk_packagemanager_enable	= 1,
	$spacewalk_packagemanager_gpgcheck	= 1,
	$spacewalk_packagemanager_removes	= [],
) inherits spacewalk{

	tidy { 'spacewalk_packagemanager_removes':
		recurse	=> 1,
	}

	case $::osfamily {
		"redhat":   { 
			class{"spacewalk::client::packagemanager::redhat": 
				spacewalk_packagemanager_enable => $spacewalk_packagemanager_enable, 
				spacewalk_packagemanager_gpgcheck => $spacewalk_packagemanager_gpgcheck,
				spacewalk_packagemanager_removes => $spacewalk_packagemanager_removes
			} 
		}
		"suse":   { 
			class{"spacewalk::client::packagemanager::suse": 
				spacewalk_packagemanager_enable => $spacewalk_packagemanager_enable, 
				spacewalk_packagemanager_gpgcheck => $spacewalk_packagemanager_gpgcheck,
				spacewalk_packagemanager_removes => $spacewalk_packagemanager_removes
			} 
		}
		default:    {  }
	}

}
