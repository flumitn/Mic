# Coding: UTF-8
require_relative 'lib/mic.rb'
require 'mic/neologd'
require 'mic/wikipedia'
require 'sqlite3'

starttime = Time.now

SourcePath = File.expand_path('../', __FILE__)
puts "Preparing for meta-informarion"
wiki = Mic::Wikipedia.new("https://dumps.wikimedia.org/jawiki/20160601/jawiki-20160601-abstract.xml", SourcePath)
wiki_meta = wiki.read
puts "Load complete wikipedia meta-information"
mic = Mic::Neologd.new('https://github.com/neologd/mecab-ipadic-neologd.git', SourcePath)
mic.prepare
puts "Decompress complete NEologd's seed files"
mic.thread

db_file = File.join(SourcePath, 'data', 'data.sqlite3')
File.unlink db_file
sqlite = SQLite3::Database.open(db_file)
sqlite.execute "CREATE TABLE IF NOT EXISTS meta(word TEXT UNIQUE, meta TEXT, word_class TEXT, wikipedia_meta TEXT)"
#sqlite.transaction

mic.read('user-dict') do |queue, file|
  puts "Loading #{file}"
  tmp = nil
  loop do
#    print "\rcomplete #{i+1} lines"
    data = queue.pop
    if data == :end
      #sqlite.commit
      sqlite.close
      break
    end
    next if tmp == (tmp2 = data[0].downcase)
    tmp = tmp2
    sqlite.execute "INSERT INTO meta VALUES (?,?,?,?)", [data[0], data[10], data[4], wiki_meta[data].nil? ? nil : wiki_meta[data].join(",")]
  end
end


puts "All completed"
puts "Data is saved to #{db_file}"

margin = Time.now - starttime
marginmin = (margin / 60).truncate
marginsec = (margin - (marginmin * 60))
puts "margin : #{marginmin}:#{marginsec}"