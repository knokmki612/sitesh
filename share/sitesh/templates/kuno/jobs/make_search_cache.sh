#!/bin/sh

. ./site.conf

find $POSTS -name draft |
grep -E '[0-9]{14}'     |
xargs grep "."          |
sed \
	-e 's/\/draft:/:/' \
	-e 's/<[^>]*>//g' \
	-e '/.*:.*:/d' -e '/.*: *$/d' > cache/search
