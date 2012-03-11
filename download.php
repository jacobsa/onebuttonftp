<?php
	$build = 73;
	$filename = "\"OneButton FTP 1.0.zip\"";
	
	if ((bool) ini_get('register_globals'))
		die('register_globals is turned on!');
	
	if (get_magic_quotes_gpc() ||
		get_magic_quotes_runtime() ||
		(bool) ini_get('magic_quotes_sybase'))
		die ('magic quotes are turned on!');
	
	
	// -------------------------------------------------------------------------
	// Connect to the database.
	// -------------------------------------------------------------------------
	$database = mysql_connect('mysql.onebutton.org', 'obftp', 'pass');
	if (! $database)
		die('Could not connect: ' . mysql_error());
	
	if (! mysql_select_db('obftp', $database))
	{
		mysql_close($database);
		die('Could not select database: ' . mysql_error());
	}
	
	
	// -------------------------------------------------------------------------
	// Insert the download record
	// -------------------------------------------------------------------------
	$queryformat = "INSERT INTO downloads (download_datetime, download_ip, download_build) VALUES (NOW(), '%s', '%u')";
	$query = sprintf($queryformat, $_SERVER['REMOTE_ADDR'], $build);
	if (! mysql_query($query, $database))
	{
		mysql_close($database);
		die('Could not insert new update check record: ' . mysql_error());
	}
	
	
	// -------------------------------------------------------------------------
	// Clean up
	// -------------------------------------------------------------------------
	mysql_close($database);
	
	
	// -------------------------------------------------------------------------
	// Send file
	// -------------------------------------------------------------------------
	$local_file = "onebuttonftp/eEJXEnn2NbBZ";
	$filesize = filesize($local_file);
	
	header("Content-type: application/zip");
	header("Content-Disposition: attachment;filename=$filename");
	header("Content-Length: $filesize");
	header('Pragma: no-cache');
	header('Expires: 0');
	
	readfile($local_file)
?>