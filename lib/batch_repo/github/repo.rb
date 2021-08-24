module BatchRuby
  module GitHub
    class Repo
      def self.where(type: "all", per_page: 999, page: 0)
        query = {
          type: type,
          per_page: per_page,
          page: page
        }.to_query

        request_url = "#{URL}#{query}"

        collection = JSON.parse(response.body)

        collection.map do |attributes|
          new(attributes)
        end
      end

      def initialize(attributes)
        attributes.each do |key, value|
          set_instance_var(:"#{key}", value) if respond_to?("#{key}")
        end
      end

      attr_reader :name
      attr_reader :full_name
      attr_reader :url

      private

      URL = "https://api.github.com/orgs/organisation/repos"
    end
  end
end
