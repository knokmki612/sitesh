#!/bin/sh

. ./site.conf

entry=$(cat << +
$(ls -f $POSTS | grep -oE '^[0-9]{4}')
$(ls -f $POSTS | grep -oE '^[0-9]{6}')
+
)

archives=$(
	echo "$entry"  |
	sort -r        |
	uniq -c        |
	sed 's/^ *//g' |
	tr \  ,)

cat << HEADER > cache/archives
cat << +
<section>
  <h2>Archives</h2>
  <form action="\$URL" method="GET">
  <select class="archives" name="archive">
HEADER

for archive in $archives; do
	entry_count=$(echo $archive | cut -d ',' -f 1)
	entry_date=$(echo $archive | cut -d ',' -f 2)
	year=$(echo $entry_date | cut -c 1-4)
	month=$(echo $entry_date | cut -c 5-)
	if [ -z "$month" ]; then
		echo "  <option value=\"$entry_date\">${year}年 ($entry_count)</option>" >> cache/archives
	else
		echo "  <option value=\"$entry_date\">${year}年${month}月 ($entry_count)</option>" >> cache/archives
	fi
done

cat << FOOTER >> cache/archives
  </select>
  <input class="archives" type="submit" value="»">
  </form>
</section>
+
FOOTER
