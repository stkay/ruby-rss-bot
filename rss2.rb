require 'feed-normalizer'
require 'open-uri'
require 'twitter'
require 'sqlite3'
require 'pit'
require 'opengraph'

partsbot = Pit.get('PartsBot')

#twitter
client = Twitter::REST::Client.new(
	consumer_key:        partsbot['consumer_key'],
	consumer_secret:     partsbot['consumer_secret'],
	access_token:        partsbot['access_token'],
	access_token_secret: partsbot['access_token_secret']
)

class Rss
	def initialize(name, uri, range, twitter_client)
		time = Time.now.to_i
		db = SQLite3::Database.open "ruby-rss-bot.sqlite3"

		#その日に取得したフィード
		record = db.execute "select * from #{name} where time > #{time} - 86400 order by time desc;"

		uri_parsed = URI.parse uri
		feeds = FeedNormalizer::FeedNormalizer.parse open(uri_parsed)
		entries = feeds.entries

		#rangeで指定したぶんRSSを読む
		(range).each do |num|
			title = entries[num].title
			link = entries[num].url
			feed = title + " " + link

			#dbを見て重複をチェックする
			repeated = false
			record.each do |data|
				if data[0] == feed then
					repeated = true
				end
			end

			#dbに突っ込んでつぶやく
			if !repeated then	
				db.execute "insert into #{name} values ('#{feed}', '#{time}');"
				twitter_client.update(feed)
			end	
		end

		p name+" end"
	end
end

#各サイト
akizuki = Rss.new("akizuki", 'http://shokai.herokuapp.com/feed/akizuki.rss', 2..21, client)
aitendo = Rss.new("aitendo", 'http://www.aitendo.com/rss/rss.php', 0..29, client)
slinux = Rss.new("slinux", 'http://pipes.yahoo.com/pipes/pipe.run?_id=43d7a8defa45bcda73071c0a157abadf&_render=rss', 0..19, client)
