cat << +
<!DOCTYPE html>
<html>
<head lang="ja">
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  <link rel="icon" type="image/x-icon" href="${URL}favicon.ico">
  <link rel="stylesheet" href="${URL}normalize.css">
  <link rel="stylesheet" href="${URL}style.css">
</head>
<body>
<div class="outer">
<div class="vertical-line"></div>
<div class="inner-margin">
<header class="column-right">
<div class="content-vertical-center">
<div class="content-max-width">
  <h1><a href="$URL">$SITE_NAME</a></h1>
  <p>$SITE_DESCRIPTION</p>
</div>
</div>
</header>
</div>
</div>
<div class="outer-main">
<div class="vertical-line"></div>
<div class="inner-margin">
<div class="column-right">
<nav id="global-menu" class="clearfix">
  <ul>
  <li><a href="$URL?archive=latest">blog</a></li>
  <li><a href="${URL}post/about">about</a></li>
  <li><a href="${URL}post/product">product</a></li>
  </ul>
</nav>
<div id="main" class="link-style">
<div class="content-margin">
<div class="content-max-width">
$article
$pager
</div>
</div>
</div>
</div>
</div>
<div class="column-left">
<div id="search">
  <form action="$URL" method="GET">
  <div class="inner-margin">
  <input class="search-box" type="text" name="search" placeholder="記事検索">
  </div>
  <button class="search-icon" type="submit">
  <span class="icon-">search</span>
  </button>
  </form>
</div>
<aside id="side-menu" class="link-style">
<div class="content-margin">
<section>
  <h2>Feeds</h2>
  <a class="rss-icon" href="${URL}rss/"><span class="icon-">rss</span></a>
</section>
$labels
$archives
$features
</div>
</aside>
</div>
</div>
<div class="outer">
<div class="vertical-line"></div>
<div class="inner-margin">
<footer class="column-right">
<div class="content-vertical-center">
  <p>&copy; 2015 $COPYRIGHT_OWNER</p>
</div>
</footer>
</div>
</div>
</body>
</html>
+
