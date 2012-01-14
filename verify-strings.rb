#!/usr/bin/env ruby
require 'set'

class Translation
  attr_reader :pre, :key, :value, :line, :language

  def initialize(pre, line, key, value, language, track_unused = true)
    @pre = pre
    @key = key
    @value = value
    @line = line
    @language = language
    @track_unused = track_unused
  end

  def track_unused?
    @track_unused
  end

end

class Strings
  attr_reader :path, :language

  def initialize(language)
    @translations = []
    @language = language
  end

  def load(path)
    @path = path
    File.open(path, 'r') do |file|
      # puts "Loading #{path}"
      pre = ''
      lc = 0
      while (line = file.gets)
        lc += 1
        # next if line.match(/#{@language}/)
        line = "/* */" if line.match(/No comment provided/)
        next if line.match(/^\s*$/)

        k, v = line.scan(/"(.*)"\s*=\s*"(.*)"/).flatten
        # puts "#{@language}: #{k} = #{v}"
        if k and v
          @translations << Translation.new(pre, lc, k, v, language, ! (line =~ /#\s+runtime\s*$/))
          pre = ''
        else
          pre += line
        end
      end
    end
    self
  end

  def keys
    @translations.map { |t| t.key }
  end

  def [](key)
    @translations.select { |t| t.key == key }
  end

  def <<(translation)
    @translations << translation
  end

  def save
    # @translations.sort! { |x,y| x.key.downcase <=> y.key.downcase }
    File.open(@path, 'w') do |file|
      @translations.each do |t|
        file.puts "#{t.pre}"
        file.puts "\"#{t.key}\" = \"#{t.value}\";"
        file.puts
      end
    end
  end
end

def verify(dirs)
  # load strings files
  strings = []
  Dir.glob(dirs.map { |arg| File.join(arg, '/**/*.lproj/*.strings') }, 0).each do |path|
    language = path.scan(/([^\/]*)\.lproj/).flatten.first
    strings << Strings.new(language).load(path)
  end

  # find the key union
  all_keys = Set.new
  strings.each do |s|
    all_keys.merge(s.keys)
  end

  # check for each key in all string files
  all_keys.each do |k|
    translations = []
    strings.each do |s|
      values = s[k]
      translations += values
      if values.size == 0
        # puts "WARN: key '#{k}' is missing in #{s.path}"
        puts "%s:%d: warning: missing key '%s'" % [ s.path, 0, k ]
        s << Translation.new('', 0, k, '', s.language)
      elsif values.size > 1
        # puts "ERROR: duplicate key '#{k}' in"
        values.each do |t|
          # puts " #{s.path}:#{t.line}"
          puts "%s:%d: error: duplicate key '%s'" % [ s.path, t.line, k ]
        end
      end
    end

    # puts "#{k} =>"
    # translations.each do |t|
    #   puts "\t#{t.language}: \t#{t.value}"
    # end
    # puts
  end

  def keys_in_line(line)
    return [] if line.start_with?('//')
    return [] if line.start_with?('/*')
    line.scan(/NSLocalizedString\(@"(.*?)",/).flatten
  end

  ret = 0

  # find keys from source files
  unused_keys = Set.new(all_keys)
  Dir.glob(dirs.map { |arg| File.join(arg, '/**/*.m') }, 0).each do |path|
    File.open(path, 'r') do |file|
      lc = 0
      while (line = file.gets)
        lc += 1
        keys_in_line(line.strip).each do |key|
          if all_keys.include?(key)
            unused_keys.delete(key)
          else
            puts "%s:%d: error: missing key '%s'" % [ path, lc, key ]
            # TODO for save support we should add a Translation object here
            ret = 1
          end
        end
      end
    end
  end

  # print unused keys
  unused_keys.each do |key|
    strings.each do |s|
      s[key].each do |t|
        if t.track_unused?
          puts "%s:%d: warning: unused key '%s'" % [ s.path, t.line, key ]
          ret = 1
        end
      end
    end
  end

  # TODO extract keys from nib files

  # strings.each { |s| s.save }
  return ret
end

ret = if ARGV.length == 0
  verify(Dir.glob(File.join(ENV['PROJECT_DIR'] || ".", "*"), 0).reject { |s| [ "frameworks", "research" ].include?(File.basename(s).downcase) })
else
  verify(ARGV)
end

exit ret