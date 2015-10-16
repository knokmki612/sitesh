#!/bin/sh
. ~/site.conf
eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
echo ""

list=$(ssh $SITE_DOMAIN "ls -U $SITE_ABSOLUTE_PATH$SITE_POSTS_DIR | sort -nr")
echo "$list" | nl
echo ""
echo -n 'select by number: '
read select_num
select_num=$(echo $select_num | sed 's/\([^ ]*\)/-e \1p/g')
echo ""

echo "$list" | sed -n $select_num | xargs -I @ scp -rp $SITE_DOMAIN:$SITE_ABSOLUTE_PATH${SITE_POSTS_DIR}@ $(pwd)

echo ""
eval $(ssh-agent -k)
exit 0
