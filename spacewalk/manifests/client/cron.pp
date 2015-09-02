class spacewalk::client::cron (
	$spacewalk_cron_minute,
	$spacewalk_cron_hour,
	$spacewalk_cron_monthday,
	$spacewalk_cron_month,
	$spacewalk_cron_weekday,
	$spacewalk_cron_randomize_sec					= 0,
	$enable											= false,
	$ensure											= 'stopped',

) inherits spacewalk::client {

	#####variables==start#####
	#####variables==end#####

	if $spacewalk_cron_randomize_sec {
		$randomize = "sleep \$((RANDOM\%${spacewalk_cron_randomize_sec}));"
	}

	$command = "${randomize}/usr/sbin/rhn_check -vv>/var/log/rhn_check.output 2>&1"
	cron {
		"spacewalk_rhn_check_cron":
		command 	=> $command,
		minute  	=> $spacewalk_cron_minute,
		hour		=> $spacewalk_cron_hour,
		monthday	=> $spacewalk_cron_monthday,
		month		=> $spacewalk_cron_month,
		weekday		=> $spacewalk_cron_weekday,
		user   	 	=> 'root',
		ensure  	=> present,
	}

	service { 'rhnsd':
		ensure		=> $ensure,
		enable		=> $enable,
	}

}
