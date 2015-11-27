cat << +
<!DOCTYPE html>
<html>
<head>
  <title>$title</title>
</head>
<body>
<h1><a href="$URL">$SITE_NAME</a></h1>
<p>$SITE_DESCRIPTION</p>
$article
$pager
<h2>Feeds</h2>
<a href="${URL}rss/">rss</a>
$labels
$archives
$features
<p>&copy; 2015 $COPYRIGHT_OWNER</p>
</body>
</html>
+
