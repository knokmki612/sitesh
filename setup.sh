#!/bin/sh

cd $(dirname $0)
prefix=/usr/local
bin=$prefix/bin
share=$prefix/share

if [ $# -ne 1 ]; then
	cat <<- + 1>&2
		please execute with subcommand 'install' or 'uninstall'.
		
		example: setup.sh install
	+
	exit 0
fi

install() {
	cp -rv bin share $prefix || exit 1
}

uninstall() {
	for command in $(find bin -type f | xargs -I{} basename {}); do
		rm -v $bin/$command || exit 1
	done
	rm -rv $share/sitesh || exit 1
}

case $1 in
	install)
		install
		;;
	uninstall)
		uninstall
		;;
esac

echo "done!"
exit 0
