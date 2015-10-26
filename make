#!/bin/sh

if [ $# -ne 1 ]; then
	echo 'usage: draft2html [$(date +%Y%m%d%H%M%S).draft]'
	exit 1
fi

if [ ! -f "$1" ]; then
	echo 'no such file.'
	exit 1
fi

draft=$(basename $1)
cd $(dirname $1)

if [ "$draft" = 'draft' ]; then
	before_post=$(basename $(pwd))
	draft="$before_post/$draft"
	cd ../
elif echo "$draft" | grep -sq '\.draft$'; then
	# 初めて整形するファイルはとりあえずUTF-8に変換
	nkf -w --overwrite $draft
else
	echo 'usage: draft2html [$(date +%Y%m%d%H%M%S).draft]'
	exit 1
fi

if echo "$draft" | grep -sqE '^[0-9]{14}' ;then
	raw_date=$(
		echo $draft             |
		$sed_exec 's/[./].*$//' |
		cut -d '-' -f 1)
	formatted_date=$(
		echo $raw_date |
		cut -c 1-8     |
		$date_exec -f - +%Y/%m/%d) || exit 1
	datetime=$(
		echo $raw_date                |
		cut -c 1-12                   |
		$sed_exec 's/\(.\{8\}\)/\1 /' |
		$date_exec -f - +%Y-%m-%dT%H:%M%:z) || exit 1
	pubdate=$(
		echo $raw_date            |
		$sed_exec \
			-e 's/\(.\{2\}\)\(.\{2\}\)\(.\{2\}\)$/\1:\2:\3/g'  \
			-e 's/^\(.\{8\}\)/\1 /' |
		$date_exec -Rf - ) || exit 1

	title=$(
		cat $draft      |
		head -n 1       |
		cut -d ':' -f 2 |
		$sed_exec -e 's/^ *//g')
	title_encoded=$(
		echo "$title"       |
		nkf -WwMQ           |
		$sed_exec 's/=$//'  |
		tr -d '\n'          |
		tr = %)
	labels=$(
		cat $draft              |
		head -n 2               |
		tail -n 1               |
		cut -d ':' -f 2         |
		$sed_exec -e 's/^ *//g' |
		tr , '\n')
	permalink=$(
		cat $draft      |
		head -n 3       |
		tail -n 1       |
		cut -d ':' -f 2 |
		$sed_exec -e 's/^ *//g')

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
	echo "$labels" | diff $post/label - > /dev/null 2>&1 || echo "$labels" > $post/label &

	for label in $(echo "$labels"); do
		label_encoded=$(
		echo $label        |
		nkf -WwMQ          |
		$sed_exec 's/=$//' |
		tr -d '\n'         |
		tr = %)
		labels_string="$labels_string<a href=\"\$SITE_URL?label=$label_encoded\">$label</a>,"
	done
	labels_string=$(echo $labels_string | $sed_exec 's/,$//')

	sentence=$(cat $draft | $sed_exec '1,4d' | tr -d '\r')
else
	# 記事以外の固定ページの作成
	title=$(
		cat $draft      |
		head -n 1       |
		cut -d ':' -f 2 |
		$sed_exec -e 's/^ *//g')

	post=$(echo "$draft" | $sed_exec 's/[./].*$//')

	if [ ! -d "$post" ]; then
		mkdir $post
	fi

	sentence=$(cat $draft | $sed_exec '1,2d' | tr -d '\r')
fi

# スペースを含んだメッセージに対応するため、スペース区切りを無効化
IFS_BACKUP=$IFS
IFS='
'
# 上から順番に画像タグを検出
while true; do
	image=$(echo "$sentence" |  grep -n -m 1 '.*\.\(png\|jpeg\|jpg\):')

	if [ $? -ne 0 ]; then
		break
	fi

	filename=$(
		echo $image | cut -d ':' -f 2)
	alt=$(
		echo $image | cut -d ':' -f 3 | $sed_exec -e 's/^ *//g')
	linenum=$(
		echo $image | cut -d ':' -f 1)
	filename_url="\$SITE_URL\${SITE_POSTS_DIR}$post/$filename"

	if echo $image | grep -qE ':https?://[^:]*'; then
		filename=$(
			echo $image | cut -d ':' -f 2-3)
		alt=$(
			echo $image | cut -d ':' -f 4 | $sed_exec -e 's/^ *//g')

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
	filename_s=$(echo $filename | $sed_exec -e 's/\.\(png\|jpeg\|jpg\)/-s.jpg/')
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
	if echo $filename | grep -sq '\.\(jpeg\|jpg\)$'; then
		jpeg_option="-define jpeg:size=$width_s"
	fi

	if [ ! -f "$post/$filename_s" ]; then
		# なぜか$jpeg_optionが一旦変数展開してからevalしないとunrecognized opitonとされる
		eval "convert -strip $jpeg_option -resize $width_s $filepath $post/$filename_s" &
	fi

	# 連続して画像タグがある場合に、pタグをまとめる
	if \
		echo "$sentence"          |
		head -n $(($linenum - 2)) |
		tail -n 1                 |
		grep -sq '<img class="\(landscape\|portrait\)"'; then
		sentence=$(echo "$sentence" | $sed_exec \
			-e $(($linenum - 1))'d' \
			-e $linenum'a<\/p>' \
			-e $linenum"c<a href=\"$filename_url\"><img class=\"$orientation\" src=\"$filename_s_url\" alt=\"$alt\"><\/a>")
	else
		sentence=$(echo "$sentence" | $sed_exec \
			-e $linenum'i<p class="image">' \
			-e $linenum'a<\/p>' \
			-e $linenum"c<a href=\"$filename_url\"><img class=\"$orientation\" src=\"$filename_s_url\" alt=\"$alt\"><\/a>")
	fi
done

IFS=$IFS_BACKUP

# brタグ、pタグを入れる
# 文字参照に置き換え
# preタグに含まれる行をスキップする
if echo "$sentence" | grep -sq '<pre\([^<]*>\)'; then
	entity_enc() {
		echo "$sentence"   |
		$sed_exec -n \
			-e "${1}s/\(<[^<>]\+>\)/\n\1\n/g" \
			-e "${1}p"       |
		$sed_exec \
			-e '/<[^<>]\+>/p' \
			-e '/<[^<>]\+>/d' \
			-e 's/&/\&amp;/g' \
			-e 's/</\&lt;/g' \
			-e 's/>/\&gt;/g' \
			-e 's/"/\&quot;/g' \
			-e 's/&amp;\(lt;\|gt;\|quot;\)/\&\1/g' \
			-e 's/\$/\\$/g' \
			-e 's/`/\\`/g'   |
			tr -d '\n'
	}

	pre="$(echo "$sentence" | grep -n '<pre\([^<]*>\)')
$(echo "$sentence" | grep -n '</pre\([^<]*>\)')"
	pre=$(echo "$pre" | cut -d ':' -f 1 | sort -n)

	pre_range=$(echo "$pre" | paste -d ',' - -)
	
	for range in $(echo "$pre_range"); do
		start=$(echo $range | cut -d ',' -f 1)
		end=$(echo $range | cut -d ',' -f 2)

		if [ $start -eq $end ]; then
			sed_option="$sed_option -e \"${start}c$(entity_enc $start)\""
		else
			sed_option="$sed_option -e \"${start}c$(entity_enc $start)\""
			sed_option="$sed_option -e \"${end}c$(entity_enc $end)\""
		fi

		start=$(($start + 1))
		end=$(($end - 1))

		if [ $start -le $end ]; then
			sed_option="$sed_option -e \"${start},${end}s/&/\&amp;/g\""
			sed_option="$sed_option -e \"${start},${end}s/</\&lt;/g\""
			sed_option="$sed_option -e \"${start},${end}s/>/\&gt;/g\""
			sed_option="$sed_option -e \"${start},${end}s/\\\"/\&quot;/g\""
			sed_option="$sed_option -e \"${start},${end}s/&amp;\(lt;\|gt;\|quot;\)/\&\1/g\""
			sed_option="$sed_option -e \"${start},${end}s/\\\\$/\\\\\\\\$/g\""
			sed_option="$sed_option -e \"${start},${end}s/\\\`/\\\\\\\\\\\`/g\""
		fi
	done

	pre="0
$pre
$(($(
		echo "$sentence" |
		wc -l            |
		cut -d ' ' -f 1) + 1))"

	pre_range=$(echo "$pre" | paste -d ',' - -)

	for range in $(echo "$pre_range"); do
		start=$(echo $range | cut -d ',' -f 1)
		end=$(echo $range | cut -d ',' -f 2)

		start=$(($start + 1))
		end=$(($end - 1))

		if [ $start -le $end ]; then
			sed_option="$sed_option -e \"${start},${end}s/^$/<br>/g\""
			sed_option="$sed_option -e \"${start},${end}s/^\([^<| *].*\)/<p>\1<\/p>/g\""
			sed_option="$sed_option -e \"${start},${end}s/&/\&amp;/g\""
			sed_option="$sed_option -e \"${start},${end}s/&amp;\(lt;\|gt;\|quot;\)/\&\1/g\""
		fi
	done

	sentence=$(echo "$sentence" | eval "$sed_exec $sed_option")
else
	sentence=$(echo "$sentence" | $sed_exec \
		-e 's/^$/<br>/g' \
		-e 's/^\([^<| *].*\)/<p>\1<\/p>/g' \
		-e 's/&/\&amp;/g')
fi

if echo "$draft" | grep -sqE '^[0-9]{14}' ;then
	html=$(. $(dirname $0)/template-article.html.sh)
	rss=$(cat <<- EOL
	cat << EOF
	  <item>
	    <title>$title</title>
	    <link>\${SITE_URL}post/$post</link>
	    <guid>\${SITE_URL}post/$post</guid>
	    <pubDate>$pubdate</pubDate>
	    <description><![CDATA[$sentence]]></description>
	  </item>
	EOF
	EOL
	)
	echo "$rss" | diff  $post/rss - > /dev/null 2>&1 || echo "$rss" > $post/rss &
else
	html=$(cat <<- EOL
		<article>
		$sentence
		</article>
		EOL
	)
fi

# ヒアドキュメントでテンプレート化
html=$(echo "$html" | $sed_exec -e '1icat << EOF' -e '$aEOF')


echo "$title" | diff  $post/title - > /dev/null 2>&1 || echo "$title" > $post/title &
echo "$html" | diff  $post/html - > /dev/null 2>&1 || echo "$html" > $post/html &
if [ ! "$draft" = "$post/draft" ]; then
	cp $draft $post/draft &
fi

wait
find $post -type f | xargs chmod 644

exit 0