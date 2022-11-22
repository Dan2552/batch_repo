module BatchRepo
  module FileOperations
    def self.find_and_replace(path, original, replacement)
      text = File.read(path)
      replace = text.gsub(original, replacement)
      if text != replace
        File.open(path, 'w') { |file| file.puts(replace) }
      end
    end
  end
end
