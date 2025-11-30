module Parsers
  class ParserRegistry
    class << self
      def parsers
        @parsers ||= []
      end

      def register(parser_class)
        parsers << parser_class unless parsers.include?(parser_class)
      end

      def find_parser_for(sender_email)
        parsers.find { |parser| parser.can_parse?(sender_email) }
      end

      def all
        parsers
      end

      def clear!
        @parsers = []
      end
    end
  end

  ParserRegistry.register(SupplierAParser)
  ParserRegistry.register(PartnerBParser)
end
