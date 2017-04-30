# -*- coding: utf-8 -*-
require 'cgi'
require 'open-uri'
require 'rss'
require 'kconv'
require 'webrick'

class Site
  attr_reader :url, :title

  def initialize(url:"", title:"")
    @url, @title = url, title
  end

  def page_source
    @page_source ||= open(@url, &:read).toutf8
  end

  def output(formatter_klass)
    # Passed class, initialize with site object,
    # and format the output with parsed(情報を取得した配列を渡す) site array
    formatter_klass.new(self).format(parse)
  end

end

class SbcrTopics < Site

  def parse
    dates = page_source.scan(%r!(\d+)年 ?(\d+)月 ?(\d+)日<br />!)
    url_titles = page_source.scan(
      %r!^<a href="(.+?)">(.+?)</a><br />!)

    url_titles.zip(dates).map{ |(aurl, atitle), ymd| [
      CGI.unescape_html(aurl),
      CGI.unescape_html(atitle),
      Time.local(*ymd)] }
  end
end

class Formatter
  attr_reader :url, :title

  def initialize(site)
    @url = site.url
    @title = site.title
  end
end

class TextFormatter < Formatter
  # 取得結果をテキストで見せる
  def format(url_title_time_ary)
    site = "Title: #{title}\nURL: #{url}\n\n"
    url_title_time_ary.each do |aurl, atitle, atime|
      site << "* (#{atime})#{atitle}\n"
      site << "    #{aurl}\n"
    end
    site
  end
end

class RSSFormatter < Formatter

  def format(url_title_time_ary)
    RSS::Maker.make("2.0") do |maker|
      maker.channel.updated = Time.now.to_s
      maker.channel.link = url
      maker.channel.title = title
      maker.channel.description = title
      url_title_time_ary.each do |aurl, atitle, atime|
        maker.items.new_item do |item|
          item.link = aurl
          item.title = atitle
          item.description = atitle
          item.updated = Time.now.to_s
        end
      end
    end
  end
end

class RSSServlet < WEBrick::HTTPServlet::AbstractServlet

  def do_GET(req, res)
    klass, opts = @options
    res.body = klass.new(opts).output(RSSFormatter).to_s
    res.content_type = "application/xml; charset=utf-8"
  end
end

def start_server
  srv = WEBrick::HTTPServer.new(:BindAddress => '127.0.0.1', :Port => 7777)
  srv.mount('/rss.xml', RSSServlet, SbcrTopics,
  url: "http://crawler.sbcr.jp/samplepage.html",
  title: "WWW.SBCR.JP トピックス")
  # add srv.mount if needed
  trap("INT"){ srv.shutdown }
  srv.start
end

if ARGV.first == 'server'
  start_server
else
  site = SbcrTopics.new(
    url: "http://crawler.sbcr.jp/samplepage.html",
    title: "WWW.SBCR.JP トピックス"
    )
  case ARGV.first
  when "rss-output"
    puts site.output RSSFormatter
  when "text-output"
    puts site.output TextFormatter
  end
end
