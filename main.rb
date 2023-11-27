require 'rss'
require 'open-uri'
require 'terminal-notifier'
require 'sqlite3'
require 'yaml'

config = YAML.load_file('config.yaml')

interval = config.fetch('interval', 60)
upwork_rss = config['rss_url']

if upwork_rss.nil?
  puts 'Please provide a valid RSS url'
  exit
end

db = SQLite3::Database.new "upwork.db"

db.execute <<-SQL
  CREATE TABLE IF NOT EXISTS posts (
    id INTEGER PRIMARY KEY,
    title TEXT,
    link VARCHAR(255) UNIQUE,
    description TEXT,
    pub_date DATETIME
  );
SQL

while true
  URI.open(upwork_rss) do |rss|
    feed = RSS::Parser.parse(rss)

    feed.items.reverse.each do |item|
      res = db.execute <<-SQL
        SELECT * FROM posts WHERE link = '#{item.link}'
      SQL

      next if res.length > 0

      db.execute <<-SQL
        INSERT INTO posts (title, link, description, pub_date)
        VALUES ('#{item.title}', '#{item.link}', '#{item.content_encoded}', '#{item.pubDate}')
      SQL

      TerminalNotifier.notify(
        item.title,
        subtitle: item.content_encoded,
        open: item.link,
        activate: 'com.upwork.Upwork',
        sound: 'default',
      )
    end
  end

  sleep interval
end
