<?php
	if ((bool) ini_get('register_globals'))
		die('register_globals is turned on!');
	
	if (get_magic_quotes_gpc() ||
		get_magic_quotes_runtime() ||
		(bool) ini_get('magic_quotes_sybase'))
		die ('magic quotes are turned on!');
	
	$notracking = $_GET['notracking'];
	if (! isset($notracking))
	{
		$osversion = urldecode($_GET['osversion']);
		$locale = urldecode($_GET['locale']);
		$software = urldecode($_GET['software']);
		$softwareversion = urldecode($_GET['softwareversion']);
		$timezone = urldecode($_GET['timezone']);
		$uniqueid = urldecode($_GET['uniqueid']);
		
		// -------------------------------------------------------------------------
		// Check that all the required GET variables exist and are of
		// the appropriate type.  Also make sure the user is requesting data
		// for OneButton FTP and that they have specified a legal build number.
		// -------------------------------------------------------------------------
		if (! (is_string($osversion) &&
				is_string($locale) &&
				is_string($software) &&
				is_numeric($softwareversion) &&
				is_string($timezone)))
			die('Must specify appropriate values.');
		
		if ((int) $softwareversion <= 0)
			die('Illegal software version');
		
		if (! ($software === 'OneButton FTP'))
			die('Unsupported software');
			
	
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
		// Get a locale ID number
		// -------------------------------------------------------------------------
		$queryformat = "SELECT locale_id FROM locales WHERE locale_identifier = '%s'";
		$query = sprintf($queryformat, mysql_real_escape_string($locale, $database));
		$result = mysql_query($query, $database);
	
		if (! $result)
		{
			mysql_close($database);
			die('Could not perform locale query: ' . mysql_error());
		}
		
		$row = mysql_fetch_assoc($result);
		if (! $row)
		{
			$queryformat = "INSERT INTO locales (locale_identifier) VALUES ('%s')";
			$query = sprintf($queryformat, mysql_real_escape_string($locale, $database));
			if (! mysql_query($query, $database))
			{
				mysql_close($database);
				die('Could not insert new locale: ' . mysql_error());
			}
			
			$localeid = mysql_insert_id($database);
		}
		else
			$localeid = $row['locale_id'];
		
	
		// -------------------------------------------------------------------------
		// Get a timezone ID number
		// -------------------------------------------------------------------------
		$queryformat = "SELECT timezone_id FROM timezones WHERE timezone_name = '%s'";
		$query = sprintf($queryformat, mysql_real_escape_string($timezone, $database));
		$result = mysql_query($query, $database);
	
		if (! $result)
		{
			mysql_close($database);
			die('Could not perform timezone query: ' . mysql_error());
		}
		
		$row = mysql_fetch_assoc($result);
		if (! $row)
		{
			$queryformat = "INSERT INTO timezones (timezone_name) VALUES ('%s')";
			$query = sprintf($queryformat, mysql_real_escape_string($timezone, $database));
			if (! mysql_query($query, $database))
			{
				mysql_close($database);
				die('Could not insert new timezone: ' . mysql_error());
			}
			
			$timezoneid = mysql_insert_id($database);
		}
		else
			$timezoneid = $row['timezone_id'];
	
	
		// -------------------------------------------------------------------------
		// Get an OS ID number
		// -------------------------------------------------------------------------
		$queryformat = "SELECT os_id FROM osversions WHERE os_version_string = '%s'";
		$query = sprintf($queryformat, mysql_real_escape_string($osversion, $database));
		$result = mysql_query($query, $database);
	
		if (! $result)
		{
			mysql_close($database);
			die('Could not perform OS version string query: ' . mysql_error());
		}
		
		$row = mysql_fetch_assoc($result);
		if (! $row)
		{
			$queryformat = "INSERT INTO osversions (os_version_string) VALUES ('%s')";
			$query = sprintf($queryformat, mysql_real_escape_string($osversion, $database));
			if (! mysql_query($query, $database))
			{
				mysql_close($database);
				die('Could not insert new OS version: ' . mysql_error());
			}
			
			$osid = mysql_insert_id($database);
		}
		else
			$osid = $row['os_id'];
		
	
	
		// -------------------------------------------------------------------------
		// Get a user ID number
		// -------------------------------------------------------------------------
		if (is_string($uniqueid))
		{
			$queryformat = "SELECT user_id FROM users WHERE user_unique_string = '%s'";
			$query = sprintf($queryformat, mysql_real_escape_string($uniqueid, $database));
			$result = mysql_query($query, $database);
	
			if (! $result)
			{
				mysql_close($database);
				die('Could not perform unique string query: ' . mysql_error());
			}
			
			$row = mysql_fetch_assoc($result);
			
			// If we didn't get a result, unset $uniqueid so we create a new unique ID later
			if (! $row)
				unset($uniqueid);
			else
				$userid = $row['user_id'];
		}
		else
			unset($uniqueid);
		
		if (! isset($uniqueid))
		{
			$uniqueid = $_SERVER['REMOTE_ADDR'] . $_SERVER['REMOTE_PORT'];
			$uniqueid = uniqid($uniqueid, true);
			$uniqueid = md5($uniqueid);
			
			$queryformat = "INSERT INTO users (user_unique_string) VALUES ('%s')";
			$query = sprintf($queryformat, mysql_real_escape_string($uniqueid, $database));
			if (! mysql_query($query, $database))
			{
				mysql_close($database);
				die('Could not insert new user: ' . mysql_error());
			}
			
			$userid = mysql_insert_id($database);
		}
		
	
		// -------------------------------------------------------------------------
		// Insert the historical record
		// -------------------------------------------------------------------------
		$queryformat = "INSERT
							INTO updatechecks (
								updatecheck_datetime,
								updatecheck_user,
								updatecheck_software_version,
								updatecheck_os,
								updatecheck_locale,
								updatecheck_timezone
							)
							VALUES (NOW(), '%u', '%u', '%u', '%u', '%u')";
		$query = sprintf($queryformat, $userid, (int)$softwareversion, $osid, $localeid, $timezoneid);
		if (! mysql_query($query, $database))
		{
			mysql_close($database);
			die('Could not insert new update check record: ' . mysql_error());
		}
		
		
		// -------------------------------------------------------------------------
		// Clean up
		// -------------------------------------------------------------------------
		mysql_close($database);
	}
?>
<?php
	echo '<?xml version="1.0" encoding="UTF-8"?>';
	echo "\n";
?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
<?php if (! isset($notracking)) { ?>
	<key>uniqueID</key>
	<string><?php echo $uniqueid; ?></string>
<?php } ?>
	<key>OneButton FTP</key>
	<dict>
		<key>latestVersion</key>
		<dict>
			<key>buildNumber</key>
			<integer>73</integer>
			<key>releaseDate</key>
			<date>2008-02-25T07:30:00Z</date>
			<key>versionString</key>
			<string>1.0</string>
		</dict>
	</dict>
</dict>
</plist>