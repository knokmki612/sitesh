#!/bin/sh
. ~/site.conf
eval $(ssh-agent)
trap 'eval $(ssh-agent -k); exit 1' 1 2 3 15
ssh-add ~/.ssh/id_rsa
echo ""

list=$(ssh $SITE_DOMAIN "ls -U $SITE_ABSOLUTE_PATH$SITE_POSTS_DIR | sort -nr")
echo "$list" | nl

while true; do
	echo ""
	echo -n '(? for help, q for quit): '
	read select_num
	if echo $select_num | grep -sq '[0-9|,$]'; then
		break
	elif [ $select_num = 'q' ]; then
		eval $(ssh-agent -k)
		exit 0
	fi
	echo ""
	cat <<- EOM
	  example(single specification): 1 3 6 9
	  example(range specification): 2,5 10,$
	EOM
done
select_num=$(echo $select_num | sed 's/\([^ ]*\)/-e \1p/g')
echo ""

echo "$list" | sed -n $select_num | xargs -I @ scp -rp $SITE_DOMAIN:$SITE_ABSOLUTE_PATH${SITE_POSTS_DIR}@ $(pwd)

echo ""
eval $(ssh-agent -k)
exit 0
