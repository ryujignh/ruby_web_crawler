require 'cgi'
require 'pp'

# page_source = parse(`/usr/local/bin/wget -q -O- http://crawler.sbcr.jp/samplepage.html`)
page_source = open("samplepage.html", &:read)
dates = page_source.scan(%r!(\d+)年 ?(\d+)月 ?(\d+)日<br />!)
pp dates[0,4]

url_titles = page_source.scan(
  %r!^<a href="(.+?)">(.+?)</a><br />!)
pp url_titles[0,4]