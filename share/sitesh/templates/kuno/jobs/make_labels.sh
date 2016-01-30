#!/bin/sh

. ./site.conf

labels=$(
	find $POSTS -name label  |
	xargs cat                |
	LANG=ja_JP.UTF-8 sort -f |
	uniq -c                  |
	sed 's/^ *//g')

cat << HEADER > cache/labels
cat << +
<section>
  <h2>Labels</h2>
  <ul class="labels">
HEADER

BACKUP_IFS=$IFS
IFS='
'
for label in $labels; do
	label_count=$(echo $label | cut -d ' ' -f 1)
	label_name=$(echo $label | cut -d ' ' -f 2-)
	label_name_encoded=$(
		echo $label_name  |
		nkf -WwMQ         |
		sed 's/=$//'      |
		tr -d '\n'        |
		tr = %)
	echo "  <li><a href=\"\$URL?label=$label_name_encoded\">$label_name</a> ($label_count)</li>" >> cache/labels
done
IFS=$BACKUP_IFS

cat << FOOTER >> cache/labels
  </ul>
</section>
+
FOOTER
