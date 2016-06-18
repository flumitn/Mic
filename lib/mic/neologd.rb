require 'fileutils'
require 'xz'
require 'csv'

module Mic
  class Neologd
    attr_reader :repo
    def initialize(repo, path)
      @repo = repo
      @SourcePath = path
      repo_name = File.basename(repo, ".git")
      `cd #{@SourcePath}; git clone #{@repo}` unless File.exist?(File.join(@SourcePath, repo_name))
      @workind_dir = File.join(@SourcePath, repo_name)
      @tmp_dir = File.join(@workind_dir, 'seed', 'tmp')
      @data = nil
      @thread = false
    end

    def decompress_xz(file)
      XZ.decompress_file(file, File.join(@tmp_dir, File.basename(file, '.xz')))
    end

    def prepare
      FileUtils.mkdir(@tmp_dir) unless FileTest.exist?(@tmp_dir)
      Dir.glob(File.join(@workind_dir, 'seed', '*.xz')){|xz|decompress_xz(xz)}
    end

    def thread(t=true)
      if t
        @thread = t
        require 'thread'
        @data = Queue.new
      end
    end

    def read(type="")
      Dir.glob(File.join(@tmp_dir, "*#{type}*.csv")).each do |csv|
        if @thread
          Thread.abort_on_exception = true
          t = Thread.new{yield(@data, csv)}
#          CSV.foreach(csv) do |row| #margin : 10:41.026183999999944遅い
#            return unless t.alive?
#            @data.push row
#          end
          File.open(csv) do |f| #margin : 6:15.55883
            f.each_line do |line|
              return unless t.alive?
              @data.push line.split(",")
            end
          end
          @data.push :end
        else
          @data = CSV.read(csv)
          yield(@data)
        end
      end
    end
  end
end
