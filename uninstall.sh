#!/bin/sh
bin=$(which site)
if [ $? -eq 0 ]; then
	bin=$(dirname "$bin")
	sudo rm -r $bin/site $bin/post $bin/../share/sitesh
else
	echo "sitesh not found"
fi
