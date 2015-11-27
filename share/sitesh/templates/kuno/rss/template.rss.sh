cat << +
<?xml version='1.0' encoding='UTF-8'?>
<rss version='2.0'>

  <channel>
    <title>$SITE_NAME$filter_name</title>
    <link>${URL}</link>
    <lastBuildDate>$date</lastBuildDate>
    <description>$SITE_DESCRIPTION</description>
    <language>ja</language>

$item
  </channel>
</rss>
+
