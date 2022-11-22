module BatchRepo
  module FileOperations
    class Rollback < StandardError; end

    def self.transaction_with_rollback(path, &blk)
      File.transaction(path) do |directory|
        yield directory
        raise Rollback
      end
    rescue Rollback
    end
  end
end
