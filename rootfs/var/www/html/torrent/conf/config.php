<?php

	@define('HTTP_USER_AGENT', 'Mozilla/5.0 (Windows NT 6.0; WOW64; rv:12.0) Gecko/20100101 Firefox/12.0', true);
	@define('HTTP_TIME_OUT', 60, true);
	@define('HTTP_USE_GZIP', true, true);
	@define('RPC_TIME_OUT', 20, true);
	@define('LOG_RPC_CALLS', false, true);
	@define('LOG_RPC_FAULTS', true, true);
	@define('PHP_USE_GZIP', false, true);
	@define('PHP_GZIP_LEVEL', 2, true);

	$httpIP = null;
	$schedule_rand = 10;
	$do_diagnostic = true;
	$log_file = '/tmp/stdout-rtorrent.log';
	$saveUploadedTorrents = true;
	$overwriteUploadedTorrents = false;
	$topDirectory = '/data/torrents';
	$forbidUserSettings = false;
	$scgi_port = 5000;
	$scgi_host = "127.0.0.1";
	$XMLRPCMountPoint = "<webroot>RPC";
	$pathToExternals = array(
        "php"       => '/usr/bin/php7',
        "curl"      => '/usr/bin/curl',
        "gzip"      => '/usr/bin/gzip',
        "id"        => '/usr/bin/id',
        "stat"      => '/usr/bin/stat',
        "cksfv"     => '/usr/bin/cksfv',
        "pgrep"     => '/usr/bin/pgrep',
        "python"    => '/usr/bin/python',
	);
	$localhosts = array(
		"127.0.0.1", 
		"localhost",
	);
	$profilePath = '../share';
	$profileMask = 0777;
	$tempDirectory = null;
	$canUseXSendFile = true;
	$locale = "UTF8";

?>
