module BatchRuby
  module File
    def self.find_and_replace(path, old, new)
      text = File.read(path)
      replace = text.gsub(old, new)
      if text != replace
        puts path
        File.open(path, 'w') { |file| file.puts replace }
      end
    end
  end
end
