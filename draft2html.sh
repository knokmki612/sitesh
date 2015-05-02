#!/bin/sh
draft=$1
tmp=./tmp

if [ $# -ne 1 ]; then
	echo 'usage: draft2html [`date +%Y%M%d`-draft]'
	exit 1
fi

# スペースを含んだメッセージに対応するため、スペース区切りを無効化
IFS_BACKUP=$IFS
IFS=$'\n'

date=`
	echo $draft     |
	cut -d '-' -f 1 |
	date -f - +%Y/%m/%d`
title=`
	cat $draft      |
	head -n 1       |
	cut -d ':' -f 2 |
	sed -e 's/^ *//g'`
labels=`
	cat $draft       |
	head -n 2        |
	tail -n 1        |
	cut -d ':' -f 2  |
	sed -e 's/^ *//g'|
	tr , '\n'`

# なんか変数スコープおかしいけどシェルのご愛嬌ってことで
for label in `echo "$labels"`; do
	labels_string=$labels_string`echo '<a href="'$label'">'$label'</a>',`
done
labels_string=`echo $labels_string | sed 's/,$//'`

cat << HEADER > $tmp
<article>
<aside class="clearfix">
<div class="social-icon">
  <a href="index.html"><img src="twitter.svg" alt="Share on Twitter"></a>
  <a href="index.html"><img src="facebook.svg" alt="Share on Facebook"></a>
  <a href="index.html"><img src="googleplus.svg" alt="Share on Google+"></a>
</div>
<div class="date">
  <time>$date</time>
</div>
<div class="labels">
  $labels_string
</div>
</aside>
<h2>$title</h2>
HEADER

# htmlタグに対応するための一時ファイル
cat $draft    |
sed '1,3d'    |
grep -ve '^#' |
tr -d '\r' >> $tmp

# 上から順番に画像タグを検出
while true; do
	image=`
		grep -n -m 1 -e '\(.*.png\|.*.jpeg\|.*.jpg\):' $tmp`
	if [ $? -ne 0 ]; then
		break
	fi

	linenum=`
		echo $image | cut -d ':' -f 1`
	filename=`
		echo $image | cut -d ':' -f 2`
	alt=`
		echo $image | cut -d ':' -f 3 | sed -e 's/^ *//g'`

	if [ ! -f $filename ]; then
		echo "$filename: No such image in this directory."
		exit 1
	fi

	# 向き判定のついでに圧縮した画像を生成
	filename_s=`echo $filename | sed -e 's/\.\(png\|jpeg\|jpg\)/-s.jpg/'`
	width=`
		identify $filename | cut -d ' ' -f 3 | cut -d 'x' -f 1`
	height=`
		identify $filename | cut -d ' ' -f 3 | cut -d 'x' -f 2`

	if [ $width -ge $height ]; then
		orientation='landscape'
		if [ ! -f $filename_s ]; then
			convert -geometry 588x $filename $filename_s
		fi
	else
		orientation='portrait'
		if [ ! -f $filename_s ]; then
			convert -geometry 288x $filename $filename_s
		fi
	fi

	# 連続して画像タグがある場合に、pタグをまとめる
	if \
		cat $tmp                     |
		head -n `expr $linenum - 2`  |
		tail -n 1                    |
		grep -sq -e '<img class="\(landscape\|portrait\)"'; then
		sed -i \
			-e `expr $linenum - 1`'d' \
			-e $linenum'a<\/p>' \
			-e $linenum'c<a href="'$filename'"><img class="'$orientation'" src="'$filename_s'" alt="'$alt'"><\/a>' $tmp
	else
		sed -i \
			-e $linenum'i<p class="image">' \
			-e $linenum'a<\/p>' \
			-e $linenum'c<a href="'$filename'"><img class="'$orientation'" src="'$filename_s'" alt="'$alt'"><\/a>' $tmp
	fi
done

IFS=$IFS_BACKUP

# brタグ、pタグを入れる
sed -i -e 's/^$/<br>/g' -e 's/^\([^<| *].*\)/<p>\1<\/p>/g' $tmp

echo '</article>' >> $tmp
cat $tmp
rm $tmp

exit 0
