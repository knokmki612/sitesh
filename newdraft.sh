#!/bin/sh
if [ -n "$1" ]; then
	cat <<- EOL > "$1".draft
	Title:
	Write from next line:
	EOL
else
	cat <<- EOL > `date +%Y%m%d%H%M%S`.draft
	Title: 
	Label: 
	Permalink: 
	Write from next line:
	EOL
fi
exit 0
