#!/bin/dash
new_date=$(date +%Y%m%d%H%M%S)-$(echo $1 | cut -d '-' -f 2-)
mv $1 $new_date
./draft2html.sh $new_date/draft
