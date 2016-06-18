module Mic
  class Wikipedia
    attr_reader :url
    def initialize(url, path)
      @url = url
      @SourcePath = path
      file_name = File.basename(url)
      `wget #{url}` unless File.exist?(@file_path = File.join(@SourcePath, file_name))
    end
    
    def read
#      doc = REXML::Document.new(File.new(@file_path)) #遅い
#      Hash.from_xml(doc.to_s)
      data = {}
      current = nil
      File.open(@file_path) do |f| #margin : 3:4.670737000000003
        f.each_line do |line|
          if m = line.match(/<title>(.*)<\/title>/)
            current = m[1].sub(/Wikipedia:\s/, "")
            data[current] = []
          elsif m = line.match(/<anchor>(.*)<\/anchor>/)
            data[current] << m[1]
          end
        end
      end
      data
    end
  end
end