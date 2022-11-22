module BatchRepo
  class DecoratedString
    def initialize(string)
      @string = string
    end

    def bg_cyan
      self.class.new("\e[46m#{@string}\e[0m")
    end

    def bg_blue
      self.class.new("\e[44m#{@string}\e[0m")
    end

    def bold
      self.class.new("\e[1m#{@string}\e[22m")
    end

    def to_s
      @string
    end
  end
end
