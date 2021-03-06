require "reeper/express/named_type"

module Reeper
  module Express
    class DefinedType < NamedType
      def initialize(options = {})
        @options = options
        @schema = options.fetch(:schema)
      end

      def parse
        document = @options.fetch(:document)
        extract_type_attributes(document)

        self
      end

      def self.parse(document, schema)
        new(document: document, schema: schema).parse
      end

      private

      def extract_type_attributes(document)
        @name = document.attributes["name"].to_s
        @wheres = extract_where_rules(document)
      end

      def extract_where_rules(document)
        document.xpath("where").map do |where|
          Express::WhereRule.parse(where)
        end
      end
    end
  end
end
