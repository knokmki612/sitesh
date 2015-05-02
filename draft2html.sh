#!/bin/sh
draft=$1
tmp=./tmp

if [ $# -ne 1 ]; then
	echo 'usage: draft2html [`date +%Y%M%d`-draft]'
	exit 1
fi

# htmlタグに対応するための一時ファイル
cat $draft    |
sed '1,3d'    |
grep -ve '^#' |
tr -d '\r' > $tmp

# スペースを含んだaltメッセージに対応するため、スペース区切りを無効化
IFS_BACKUP=$IFS
IFS=$'\n'

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
		echo $image | cut -d ':' -f 3`
	if [ ! -f $filename ]; then
		echo "$filename: No such image in this directory."
		exit 1
	fi

	width=`
		identify $filename | cut -d ' ' -f 3 | cut -d 'x' -f 1`
	height=`
		identify $filename | cut -d ' ' -f 3 | cut -d 'x' -f 2`
	if [ $width -ge $height ]; then
		orientation='landscape'
	else
		orientation='portrait'
	fi

	# 連続して画像タグがある場合に、pタグをまとめる
	if \
		cat $tmp                     |
		head -n $(expr $linenum - 2) |
		tail -n 1                    |
		grep -sq -e '<img class="\(landscape\|portrait\)"'; then
		sed -i \
			-e `expr $linenum - 1`'d' \
			-e $linenum'a<\/p>' \
			-e $linenum'c<a href="'$filename'"><img class="'$orientation'" src="'$filename'" alt="'$alt'"><\/a>' $tmp
	else
		sed -i \
			-e $linenum'i<p class="image">' \
			-e $linenum'a<\/p>' \
			-e $linenum'c<a href="'$filename'"><img class="'$orientation'" src="'$filename'" alt="'$alt'"><\/a>' $tmp
	fi
done

IFS=$IFS_BACKUP

# brタグ、pタグを入れる
sed -e 's/^$/<br>/g' -e 's/^\([^<].*\)/<p>\1<\/p>/g' $tmp

rm $tmp
exit 0
