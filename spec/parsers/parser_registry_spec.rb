require "rails_helper"

RSpec.describe Parsers::ParserRegistry do
  describe ".register" do
    it "registers a parser class" do
      expect(described_class.parsers).to include(Parsers::SupplierAParser)
      expect(described_class.parsers).to include(Parsers::PartnerBParser)
    end

    it "does not register duplicates" do
      initial_count = described_class.parsers.count
      described_class.register(Parsers::SupplierAParser)
      expect(described_class.parsers.count).to eq(initial_count)
    end
  end

  describe ".find_parser_for" do
    it "finds SupplierAParser for fornecedorA.com emails" do
      parser_class = described_class.find_parser_for("loja@fornecedorA.com")
      expect(parser_class).to eq(Parsers::SupplierAParser)
    end

    it "finds PartnerBParser for parceiroB.com emails" do
      parser_class = described_class.find_parser_for("contato@parceiroB.com")
      expect(parser_class).to eq(Parsers::PartnerBParser)
    end

    it "returns nil for unknown senders" do
      parser_class = described_class.find_parser_for("unknown@example.com")
      expect(parser_class).to be_nil
    end

    it "is case insensitive" do
      parser_class = described_class.find_parser_for("LOJA@FORNECEDORA.COM")
      expect(parser_class).to eq(Parsers::SupplierAParser)
    end
  end

  describe ".all" do
    it "returns all registered parsers" do
      expect(described_class.all).to be_an(Array)
      expect(described_class.all.count).to be >= 2
    end
  end
end
