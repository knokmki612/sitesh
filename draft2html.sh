#!/bin/sh
draft=$1
tmp=./tmp
cat $draft | sed '1,3d' | tr -d '\r' > $tmp

for file in `sed -e '/^\(.*[.png|.jpeg|.jpg]\)$/!d' $tmp | sort -u`; do
	if [ ! -f $file ]; then
		echo "$file: No such image in this directory."
		exit 1
	fi
done

sed -e 's/^$/<br>/g' -e 's/^\([^<].*\)/<p>\1<\/p>/g' $tmp
#-e 's/^\(.*[.png|.jpeg|.jpg]\)$/<p class="image"><a href="\1"><img class="landscape" src="\1" alt=""><\/a><\/p>/g' 

rm $tmp
exit 0
