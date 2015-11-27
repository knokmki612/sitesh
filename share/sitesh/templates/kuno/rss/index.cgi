#!/bin/dash

. ../site.conf

echo 'Content-Type: application/rss+xml; charset="utf-8"'
echo ''

date=$(date -R)

queries=$(echo $QUERY_STRING | tr '&' '\n')

if [ -z "$queries" ]; then
	item=$(
		find ../$POSTS -name rss |
		grep -E '[0-9]{14}'      |
		sort -r                  |
		xargs -I @ dash -c ". @")
	filter_name=" (全て)"
	. ./template.rss.sh
	exit 0
fi

for query in $(echo "$queries"); do
	request_key=$(echo $query | cut -d '=' -f 1)
	request_param=$(echo $query | cut -d '=' -f 2)
	request_param=$(echo $request_param| nkf --url-input)
	filter="$filter$request_param\|"
	filter_name="$filter_name$request_param,"
done

filter=$(echo $label | sed 's/\\|$//')
filter_name=" ($(echo $filter_name | sed 's/,$//'))"
item=$(
	find ../$POSTS -name label |
	xargs grep -l "$filter"    |
	sed 's/\/label$/\/rss/'    |
	sort -r                    |
	xargs -I @ dash -c ". @")

. ./template.rss.sh

exit 0
