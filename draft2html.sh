#!/bin/dash

if [ $# -ne 1 ]; then
	echo 'usage: draft2html [$(date +%Y%m%d)-draft]'
	exit 1
fi

draft=$(basename $1)
tmp=$(mktemp)
cd $(dirname $1)

if [ "$draft" = 'draft' ]; then
	before_post=$(basename $(pwd))
	draft="$before_post/$draft"
	cd ../
else
	# 初めて整形するファイルはとりあえずUTF-8に変換
	nkf -w --overwrite $draft
fi

if echo "$draft" | grep -sqE '^[0-9]{14}' ;then
	raw_date=$(echo $draft | sed 's/[./].*$//' | cut -d '-' -f 1)
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

	if [ "$permalink" = '' ]; then
		post="$raw_date"
	elif echo "$permalink" | grep -sq '[^A-Za-z0-9-]'; then
		echo "$draft: Please set permalink at start from alphanumeric character."
		exit 1
	else
		post="$raw_date-$permalink"
	fi

	if [ ! -d "$post" ]; then
		mkdir $post
	fi
	echo "$labels" > $post/label

	for label in $(echo "$labels"); do
		label_encoded=$(
		echo $label  |
		nkf -WwMQ    |
		sed 's/=$//' |
		tr -d '\n'   |
		tr = %)
		labels_string=$labels_string$(echo "<a href=\"$SITE_URL?label=$label_encoded\">$label</a>,")
	done
	labels_string=$(echo $labels_string | sed 's/,$//')

	sentence=$(cat $draft | sed '1,4d' | tr -d '\r')

	# htmlタグに対応するための一時ファイル
	. $(dirname $0)/template-article.html.sh > $tmp
else
	# 記事以外の固定ページの作成
	title=$(
		cat $draft      |
		head -n 1       |
		cut -d ':' -f 2 |
		sed -e 's/^ *//g')

	post=$(echo "$draft" | sed 's/[./].*$//')

	if [ ! -d "$post" ]; then
		mkdir $post
	fi

	sentence=$(cat $draft | sed '1,2d' | tr -d '\r')

	# htmlタグに対応するための一時ファイル
	cat <<- EOL > $tmp
	<article>
	$sentence
	</article>
	EOL
fi

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

	filename=$(
		echo $image | cut -d ':' -f 2)
	alt=$(
		echo $image | cut -d ':' -f 3 | sed -e 's/^ *//g')
	linenum=$(
		echo $image | cut -d ':' -f 1)
	filename_url="\$SITE_URL\${SITE_POSTS_DIR}$post/$filename"

	if echo $image | grep -qE ':https?://[^:]*'; then
		filename=$(
			echo $image | cut -d ':' -f 2-3)
		alt=$(
			echo $image | cut -d ':' -f 4 | sed -e 's/^ *//g')

		filename_url="$filename"
		filename=$(basename $filename)
		filepath="$post/$filename"

		# 既にローカルにファイルがあったら取ってこない
		if [ -f "$filepath" ]; then
			wget --spider $filename_url || exit 1
		else
			wget $filename_url -O $filepath || exit 1
		fi

	elif [ -f "$filename" ]; then
		filepath="$filename"
	elif [ -f "$post/$filename" ]; then
		filepath="$post/$filename"
	elif [ -n "$before_post" ] && [ -f "$before_post/$filename" ]; then
		filepath="$before_post/$filename"
	else
		echo "$filename: No such image in post directory and parent directory."
		exit 1
	fi

	if [ ! -f "$post/$filename" ]; then
		cp $filepath $post/$filename &
	fi

	# 向き判定のついでに圧縮した画像を生成
	filename_s=$(echo $filename | sed -e 's/\.\(png\|jpeg\|jpg\)/-s.jpg/')
	filename_s_url="\$SITE_URL\${SITE_POSTS_DIR}$post/$filename_s"
	width=$(
		file $filepath                 |
		grep -oE ", [0-9]+ ?x ?[0-9]+" |
		grep -oE "[0-9]+"              |
		head -n 1)

	height=$(
		file $filepath                 |
		grep -oE ", [0-9]+ ?x ?[0-9]+" |
		grep -oE "[0-9]+"              |
		tail -n 1)

	if [ $width -ge $height ]; then
		orientation='landscape'
		width_s='588x'
	else
		orientation='portrait'
		width_s='288x'
	fi

	# jpeg画像固有のオプションをつける判定
	if echo $filename | grep -qe '\.\(jpeg\|jpg\)$'; then
		jpeg_option="-define jpeg:size=$width_s"
	fi

	if [ ! -f "$post/$filename_s" ]; then
		# なぜか$jpeg_optionが一旦変数展開してからevalしないとunrecognized opitonとされる
		eval "convert -strip $jpeg_option -resize $width_s $filepath $post/$filename_s" &
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
			-e $linenum"c<a href=\"$filename_url\"><img class=\"$orientation\" src=\"$filename_s_url\" alt=\"$alt\"><\/a>" $tmp
	else
		sed -i \
			-e $linenum'i<p class="image">' \
			-e $linenum'a<\/p>' \
			-e $linenum"c<a href=\"$filename_url\"><img class=\"$orientation\" src=\"$filename_s_url\" alt=\"$alt\"><\/a>" $tmp
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
	echo $(($(wc -l $tmp | cut -d ' ' -f 1) + 1)) >> $start_pre
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

# ヒアドキュメントでテンプレート化
sed -i -e '1icat << EOF' -e '$aEOF' $tmp

echo $title > $post/title
cp $tmp $post/html
if [ ! "$draft" = "$post/draft" ]; then
	cp $draft $post/draft
fi
rm $tmp

wait
find $post -type f | xargs chmod 644
exit 0
