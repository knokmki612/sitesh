#!/bin/sh
if [ $# -eq 0 ]; then
	echo "usage: install.sh {usr|usr/local}"
fi

case $1 in
	usr)
		sudo cp -r bin share /usr
		;;
	usr/local)
		sudo cp -r bin share /usr/local
		;;
esac
