#!/bin/sh
. ~/site.conf
echo ""

list=$(
	ls -U $(pwd)                |
	find -maxdepth 2 -name html |
	cut -d '/' -f 2             |
	sort -nr)

echo "$list" | nl
echo ""
echo -n 'select by number: '
read select_num
select_num=$(echo $select_num | sed 's/\([^ ]*\)/-e \1p/g')
echo ""

eval $(ssh-agent)
ssh-add ~/.ssh/id_rsa
echo "$list" | sed -n $select_num | xargs -I @ rsync -auvz --delete -e ssh $(pwd)/@ $SITE_DOMAIN:$SITE_ABSOLUTE_PATH${SITE_POSTS_DIR}
ssh $SITE_DOMAIN "cd $SITE_ABSOLUTE_PATH; ./make_archives.dash; ./make_labels.dash; ./make_search_cache.dash"
eval $(ssh-agent -k)

echo ""
exit 0
