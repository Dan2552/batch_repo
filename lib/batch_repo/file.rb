module BatchRuby
  module Files
    def self.find_and_replace(path, old, new)
      text = File.read(path)
      replace = text.gsub(old, new)
      if text != replace
        ::File.open(path, 'w') { |file| file.puts(replace) }
        return true
      end
      false
    end
  end
end
