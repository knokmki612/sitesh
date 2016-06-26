#!/bin/sh

cd $(dirname $0)
if [ -z "$prefix" ]; then
	prefix=/usr/local
fi

usage() {
	cat <<- + 1>&2
		please execute with subcommand 'install' or 'uninstall'.
		
		example: setup.sh install
	+
	exit 0
}

install() {
	cp -r bin share $prefix || exit 1
}

uninstall() {
	exist=$(type -p site)
	if [ -z "$exist" ]; then
		return 0
	fi
	prefix=$(echo $exist | sed 's/\/bin\/site//')
	echo "prefix: $prefix"
	bin=$prefix/bin
	share=$prefix/share
	for command in $(find bin -type f | xargs -I{} basename {}); do
		rm $bin/$command || exit 1
	done
	rm -r $share/sitesh || exit 1
}

case $1 in
	install)
		uninstall
		install
		;;
	uninstall)
		uninstall
		;;
		*)
		usage
		;;
esac

echo "done!"
exit 0
