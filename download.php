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
