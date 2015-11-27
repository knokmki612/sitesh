#!/bin/dash

. ../site.conf

echo 'Content-Type: application/rss+xml; charset="utf-8"'
echo ''

date=$(date -R)

queries=$(echo $QUERY_STRING | sed 's/&.*$//')

request_key=$(echo $query | cut -d '=' -f 1)
request_param=$(echo $query | cut -d '=' -f 2)

if [ "$request_key" = 'label' ]; then
	request_param=$(echo $request_param | nkf --url-input)
	label=" ($request_param)"
	item=$(
		find ../$POSTS -name label     |
		xargs grep -l "$request_param" |
		sed 's/\/label$/\/rss/'        |
		sort -r                        |
		xargs -I @ dash -c ". @")
else
	item=$(
		find ../$POSTS -name rss |
		grep -E '[0-9]{14}'      |
		sort -r                  |
		xargs -I @ dash -c ". @")
fi

. ./template.rss.sh

exit 0
