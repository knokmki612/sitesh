#!/bin/dash
if ! echo "$1" | grep -sqE '[0-9]{14}'; then
	echo 'usage: update-date.sh $(date +%Y%m%d)'
	exit 1
fi

new_date=$(echo "$1" | sed "s/^[0-9]\{14\}/$(date +%Y%m%d%H%M%S)/")
mv $1 $new_date

if [ -f "$new_date" ]; then
	./draft2html.sh $new_date
else
	./draft2html.sh $new_date/draft
fi
