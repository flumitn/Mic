# Coding: UTF-8
require_relative 'lib/mic.rb'
require 'mic/neologd'
require 'mic/wikipedia'

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

file_path = File.join(SourcePath, 'data', 'data.txt')
data_file = File.open(file_path, "w")
mic.read('user-dict') do |queue, file|
  puts "Loading #{file}"
  tmp = nil
  loop do
#    print "\rcomplete #{i+1} lines"
    data = queue.pop
    if data == :end
      data_file.close
      break
    end
    next if tmp == (tmp2 = data[0].downcase)
    tmp = tmp2
    data_file.puts [data[0], data[10], data[4], wiki_meta[data[10]].nil? ? nil : wiki_meta[data[10]].join(",")].join("\t")
  end
end


puts "All completed"
puts "Data is saved to #{file_path}"

margin = Time.now - starttime
marginmin = (margin / 60).truncate
marginsec = (margin - (marginmin * 60))
puts "margin : #{marginmin}:#{marginsec}"