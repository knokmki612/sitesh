#!/bin/dash

if [ $# -ne 1 ]; then
	echo 'usage: draft2html [$(date +%Y%m%d)-draft]'
	exit 1
fi

cd $(dirname $1)
draft=$(basename $1)
tmp=$(mktemp)

raw_date=$(echo $draft | cut -d '-' -f 1)
formatted_date=$(echo $raw_date | cut -c 1-8 | date -f - +%Y/%m/%d) || exit 1

title=$(
	cat $draft      |
	head -n 1       |
	cut -d ':' -f 2 |
	sed -e 's/^ *//g')
title_encoded=$(
	echo "$title" |
	nkf -WwMQ     |
	sed 's/=$//'  |
	tr -d '\n'    |
	tr = %)
labels=$(
	cat $draft        |
	head -n 2         |
	tail -n 1         |
	cut -d ':' -f 2   |
	sed -e 's/^ *//g' |
	tr , '\n')
permalink=$(
	cat $draft      |
	head -n 3       |
	tail -n 1       |
	cut -d ':' -f 2 |
	sed -e 's/^ *//g')

if [ "$permalink" = "" ]; then
	echo "$draft: Please set permalink at start from alphanumeric character."
	exit 1
fi

post="$raw_date-$permalink"

if [ ! -d $post ]; then
	mkdir $post
fi

for label in $(echo "$labels"); do
	label_encoded=$(
	echo $label  |
	nkf -WwMQ    |
	sed 's/=$//' |
	tr -d '\n'   |
	tr = %)
	labels_string=$labels_string$(echo '<a href="$SITE_URL?label='$label_encoded'">'$label'</a>',)
done
labels_string=$(echo $labels_string | sed 's/,$//')

cat << HEADER > $tmp
<article>
<aside class="clearfix">
<div class="social-icon">
  <a href="http://twitter.com/share?url=\${SITE_URL}post/$post&text=$title_encoded\$SITE_TITLE_TAIL_ENCODED"><span class="icon-twitter"></span></a>
  <a href="http://www.facebook.com/sharer.php?u=\${SITE_URL}post/$post"><span class="icon-facebook"></span></a>
  <a href="https://plusone.google.com/_/+1/confirm?hl=ja&url=\${SITE_URL}post/$post"><span class="icon-googleplus"</span></a>
</div>
<div class="date">
  <time>$formatted_date</time>
</div>
<div class="labels">
  $labels_string
</div>
</aside>
<h2><a href="\${SITE_URL}post/$post">$title</a></h2>
HEADER

# htmlタグに対応するための一時ファイル
cat $draft |
sed '1,4d' |
tr -d '\r' >> $tmp

# スペースを含んだメッセージに対応するため、スペース区切りを無効化
IFS_BACKUP=$IFS
IFS='
'
# 上から順番に画像タグを検出
while true; do
	image=$(grep -n -m 1 -e '.*\.\(png\|jpeg\|jpg\):' $tmp)

	if [ $? -ne 0 ]; then
		break
	fi

	linenum=$(
		echo $image | cut -d ':' -f 1)
	filename=$(
		echo $image | cut -d ':' -f 2)
	alt=$(
		echo $image | cut -d ':' -f 3 | sed -e 's/^ *//g')

	if [ ! -f $filename ]; then
		echo "$filename: No such image in this directory."
		exit 1
	fi

	if [ ! -f $post/$filename ]; then
		cp $filename $post/$filename &
	fi

	# 向き判定のついでに圧縮した画像を生成
	filename_s=$(echo $filename | sed -e 's/\.\(png\|jpeg\|jpg\)/-s.jpg/')
	width=$(
		file $filename                 |
		grep -oE ", [0-9]+ ?x ?[0-9]+" |
		grep -oE "[0-9]+"              |
		head -n 1)

	height=$(
		file $filename                 |
		grep -oE ", [0-9]+ ?x ?[0-9]+" |
		grep -oE "[0-9]+"              |
		tail -n 1)

	if [ $width -ge $height ]; then
		orientation='landscape'
		if [ ! -f $post/$filename_s ]; then
			convert -geometry 588x $filename $post/$filename_s &
		fi
	else
		orientation='portrait'
		if [ ! -f $post/$filename_s ]; then
			convert -geometry 288x $filename $post/$filename_s &
		fi
	fi

	# 連続して画像タグがある場合に、pタグをまとめる
	if \
		cat $tmp                  |
		head -n $(($linenum - 2)) |
		tail -n 1                 |
		grep -sq -e '<img class="\(landscape\|portrait\)"'; then
		sed -i \
			-e $(($linenum - 1))'d' \
			-e $linenum'a<\/p>' \
			-e $linenum'c<a href="$SITE_URL${SITE_POSTS_DIR}'$post/$filename'"><img class="'$orientation'" src="$SITE_URL${SITE_POSTS_DIR}'$post/$filename_s'" alt="'$alt'"><\/a>' $tmp
	else
		sed -i \
			-e $linenum'i<p class="image">' \
			-e $linenum'a<\/p>' \
			-e $linenum'c<a href="$SITE_URL${SITE_POSTS_DIR}'$post/$filename'"><img class="'$orientation'" src="$SITE_URL${SITE_POSTS_DIR}'$post/$filename_s'" alt="'$alt'"><\/a>' $tmp
	fi
done

IFS=$IFS_BACKUP

# brタグ、pタグを入れる
# preタグに含まれる行をスキップする
if grep -sq -e '<pre\([^<]*>\)' $tmp; then
	start_pre=$(mktemp)
	end_pre=$(mktemp)
	
	echo 0 > $end_pre
	grep -n -e '<pre\([^<]*>\)' $tmp | cut -d ':' -f 1 > $start_pre
	grep -n -e '</pre\([^<]*>\)' $tmp | cut -d ':' -f 1 >> $end_pre
	$(($(wc -l $tmp | cut -d ' ' -f 1) + 1)) >> $start_pre
	pre_range=$(paste -d ',' $end_pre $start_pre)

	for range in $(echo "$pre_range"); do
		start=$(echo $range | cut -d ',' -f 1)
		start=$(($start + 1))
		end=$(echo $range | cut -d ',' -f 2)
		end=$(($end - 1))

		if [ $start -lt $end ]; then
			sed -i \
				-e $start,$end's/^$/<br>/g' \
				-e $start,$end's/^\([^<| *].*\)/<p>\1<\/p>/g' $tmp
		else
			sed -i \
				-e $start's/^$/<br>/g' \
				-e $start's/^\([^<| *].*\)/<p>\1<\/p>/g' $tmp
		fi
	done
	rm $start_pre $end_pre
else
	sed -i \
		-e 's/^$/<br>/g' \
		-e 's/^\([^<| *].*\)/<p>\1<\/p>/g' $tmp
fi

cat << FOOTER >> $tmp
</article>
FOOTER

# ヒアドキュメントでテンプレート化
sed -i -e '1icat << EOF' -e '$aEOF' $tmp

cd $post
echo $title > title
echo "$labels" > label
cat ../$draft > draft
cat $tmp > html
rm $tmp

wait
find -regextype posix-egrep -regex ".*\.(png|jpg|jpeg)" | xargs --no-run-if-empty chmod 644
exit 0
