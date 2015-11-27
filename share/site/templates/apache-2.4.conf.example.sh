cat << +
<VirtualHost *:80>
	ServerAdmin webmaster@localhost
	ServerName $DOMAIN:80

	DocumentRoot $SERVER_PATH

	<Directory />
		Options FollowSymLinks
		AllowOverride None
	</Directory>

	<Directory $SERVER_PATH>
		Options ExecCGI FollowSymLinks
		AllowOverride None

		RewriteEngine on
		RewriteCond %{REQUEST_URI} ^/\$
		RewriteCond %{QUERY_STRING} ^\$
		RewriteRule ^ ?archive=latest [L]
		RewriteCond %{REQUEST_URI} ^/post/([^/]+)/?\$
		RewriteRule ^ ?post=%1 [L]

		ExpiresActive on
		ExpiresByType image/x-icon \"access plus 1 month\"
		ExpiresByType image/jpeg \"access plus 1 month\"
		ExpiresByType image/png \"access plus 1 month\"
		ExpiresByType font/truetype \"access plus 1 month\"
		<FilesMatch \"normalize.css\">
			ExpiresDefault \"access plus 1 year\"
		</FilesMatch>
	</Directory>

	<FilesMatch \"\\\.cgi\$\">
		SetHandler cgi-script
	</FilesMatch>

	ErrorLog \\\${APACHE_LOG_DIR}/error.log

	# Possible values include: debug, info, notice, warn, error, crit,
	# alert, emerg.
	LogLevel warn

	CustomLog \\\${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
+
