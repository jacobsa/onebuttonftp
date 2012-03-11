<?php
		require('includes/header.php');
?>
				<div id="maincontent">
				<h2>Privacy Info</h2>
					<p>OneButton FTP version 0.1 introduced a 'check for updates weekly' feature that is turned on by default.  By itself, this feature does not cause any data about you to be tracked - it merely retrieves some information from a web site.</p>
					<p>Along with this feature is a preference to 'provide anonymous usage data'.  This preference is turned off by default and the user is prompted about whether he wants to turn it on the first time he runs the program.  Turning this preference on causes the following data to be recorded by the OneButton FTP team when your copy of OneButton FTP checks for updates weekly:</p>
						<ul>
							<li>The date and time of the check</li>
							<li>Your OneButton FTP version number</li>
							<li>Your OS X version number</li>
							<li>Your time zone</li>
							<li>Your locale (such as US English or AU English)</li>
						</ul>
					<p>Internally, you are identified by a unique number.  However, your IP address is <i>not</i> recorded, and neither is any sensitive information such as passwords or FTP server bookmarks.  The only data collected is what is listed here, and it is entirely anonymous.  This data is similar to the data that your browser sends along every time it accesses a web page.</p>
				<h2>Why collect this data?</h2>
					<p>So why would we like you to turn on this option and contribute anonymous data? It's simple - we think that this data can help us improve OneButton FTP.  Here are a couple of examples:</p>
						<ul>
							<li>Tracking OS X version numbers can help us to see which versions of OS X we need to focus on testing for.  If we see that a significant proportion of our users are still using Panther, for example, we will be sure to find a way to test for Panther in addition to Tiger.<p></p></li>
							<li>Tracking locale and time zone allows us to see what parts of the world and language backgrounds our users come from.  This can help us focus our attention on worthwhile localizations.  If a lot of our users have their locale set to Cantonese, we will try to find a way to localize OneButton FTP in Cantonese.</li>
						</ul>
					<p>As mentioned before, the data that is tracked is completely anonymous and no more extensive than what your browser sends every time you access a web page.  So please help us improve OneButton FTP by contributing data.</p>
				<h2>Is this public?</h2>
					<p>The data that we gather is not made public (though we may use it to publish some cool charts in the future).  However, the script responsible for tracking the data can be viewed <a href="http://cvs.sourceforge.net/viewcvs.py/gosee/web/versioninfo.php?view=markup">here</a> in our CVS repository.  And of course, since OneButton FTP is open source, you can see how the data is sent to the server by taking a look at the source code.</p>
				</div>
<?php
		require('includes/footer.php');
?>