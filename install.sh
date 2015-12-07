#!/bin/sh
cd $(dirname $0)
./uninstall.sh
sudo cp -r bin share /usr/local
echo "installed!"
