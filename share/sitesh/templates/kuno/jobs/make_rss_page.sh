#!/bin/sh

. ./site.conf

labels=$(
	find $POSTS -name label  |
	xargs cat                |
	LANG=ja_JP.UTF-8 sort -f |
	uniq                     |
	sed 's/^ *//g')

cat << HEADER > cache/choose
cat << +
<article>
<h2>購読のオプション</h2>
<p>購読したいラベルを選択してください。それに合わせたRSSフィードを生成します。選択しなかった場合、全ての記事を購読します。</p>
<form action="rss/" method="GET">
<ul>
HEADER

BACKUP_IFS=$IFS
IFS='
'
for label in $labels; do
	echo "<li>$label <input type="checkbox" name="label" value="$label"></li>" >> cache/choose
done
IFS=$BACKUP_IFS

cat << FOOTER >> cache/choose
</ul>
<input type="submit" value="生成する">
</form>
</article>
+
FOOTER
