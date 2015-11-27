cat << +
<article>
<aside>
  <a href="http://twitter.com/share?url=\${URL}post/$post&text=$title_encoded\$TITLE_TAIL_ENCODED">twitter</a>
  <time datetime="$datetime">$formatted_date</time>
  $labels_string
</aside>
<h2><a href="\${URL}post/$post">$title</a></h2>
$sentence
</article>
+
