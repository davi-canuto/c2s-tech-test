require 'rails_helper'

RSpec.describe PartnerBParser do
  describe '.can_parse?' do
    context 'when email is from parceiroB.com' do
      it 'returns true for standard format' do
        expect(described_class.can_parse?('contato@parceiroB.com')).to be true
      end

      it 'returns true case insensitive' do
        expect(described_class.can_parse?('CONTATO@PARCEIROB.COM')).to be true
        expect(described_class.can_parse?('Contato@ParceiroB.Com')).to be true
      end

      it 'returns true with different subdomains' do
        expect(described_class.can_parse?('vendas@parceiroB.com')).to be true
        expect(described_class.can_parse?('suporte@parceiroB.com')).to be true
      end

      it 'returns true with subdomain' do
        expect(described_class.can_parse?('contato@shop.parceiroB.com')).to be true
      end
    end

    context 'when email is NOT from parceiroB.com' do
      it 'returns false for other domains' do
        expect(described_class.can_parse?('test@example.com')).to be false
        expect(described_class.can_parse?('loja@fornecedorA.com')).to be false
      end

      it 'returns false for similar but different domains' do
        expect(described_class.can_parse?('contato@parceiroB.com.br')).to be false
        expect(described_class.can_parse?('contato@parceiroC.com')).to be false
      end

      it 'returns false for nil' do
        expect(described_class.can_parse?(nil)).to be false
      end

      it 'returns false for empty string' do
        expect(described_class.can_parse?('')).to be false
      end
    end
  end

  describe '#parse' do
    context 'with complete valid email' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email4.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'extracts all information correctly' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Ana Costa'
        expect(result[:email]).to eq 'ana.costa@example.com'
        expect(result[:phone]).to eq '5531977771111'
        expect(result[:product_code]).to eq 'PROD-555'
        expect(result[:sender]).to eq 'contato@parceiroB.com'
      end

      it 'has no errors' do
        parser.parse
        expect(parser.errors).to be_empty
      end

      it 'returns a hash with symbol keys' do
        result = parser.parse
        expect(result.keys).to all(be_a(Symbol))
      end
    end

    context 'with valid email but no email address (only phone)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email6.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'succeeds because phone is present (email is optional)' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Fernanda Lima'
        expect(result[:email]).to be_nil
        expect(result[:phone]).to eq '61933334444'
        expect(result[:product_code]).to eq 'PROD-999'
      end
    end

    context 'with missing required contact information' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email8.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'returns nil when no email or phone is present' do
        result = parser.parse
        expect(result).to be_nil
      end

      it 'adds error message' do
        parser.parse
        expect(parser.errors).not_to be_empty
        expect(parser.errors.first).to match(/contact information/i)
      end
    end

    context 'when parse is called multiple times' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email4.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'returns consistent results' do
        result1 = parser.parse
        result2 = parser.parse

        expect(result1).to eq(result2)
      end
    end
  end

  describe '#extract_name' do
    let(:parser) { described_class.new(build_mail_with_body(body)) }

    context 'with "Cliente:" pattern' do
      let(:body) { "Cliente: Ana Costa\nOutros dados..." }

      it 'extracts name correctly' do
        expect(parser.extract_name).to eq 'Ana Costa'
      end
    end

    context 'with "Nome completo:" pattern' do
      let(:body) { "Nome completo: Ricardo Silva\nOutros dados..." }

      it 'extracts name correctly' do
        expect(parser.extract_name).to eq 'Ricardo Silva'
      end
    end

    context 'with "Nome do cliente:" pattern' do
      let(:body) { "Nome do cliente: Fernanda Lima\nOutros dados..." }

      it 'extracts name correctly' do
        expect(parser.extract_name).to eq 'Fernanda Lima'
      end
    end

    context 'with simplified "Nome:" pattern' do
      let(:body) { "Nome: Pedro Santos\nOutros dados..." }

      it 'extracts name correctly' do
        expect(parser.extract_name).to eq 'Pedro Santos'
      end
    end

    context 'with name containing special characters' do
      let(:body) { "Cliente: José de Souza-Oliveira\nOutros dados..." }

      it 'extracts name with hyphens' do
        expect(parser.extract_name).to eq 'José de Souza-Oliveira'
      end
    end

    context 'with name containing accents' do
      let(:body) { "Cliente: André Gonçalves Müller\nOutros dados..." }

      it 'extracts name with accents' do
        expect(parser.extract_name).to eq 'André Gonçalves Müller'
      end
    end

    context 'with extra whitespace' do
      let(:body) { "Cliente:    Maria Silva   \nOutros dados..." }

      it 'strips extra whitespace' do
        expect(parser.extract_name).to eq 'Maria Silva'
      end
    end

    context 'when name field is missing' do
      let(:body) { "Email: test@example.com\nTelefone: 11999999999" }

      it 'returns nil' do
        expect(parser.extract_name).to be_nil
      end
    end
  end

  describe '#extract_email' do
    let(:parser) { described_class.new(build_mail_with_body(body)) }

    context 'with "E-mail:" pattern' do
      let(:body) { "E-mail: ana@example.com\nOutros dados..." }

      it 'extracts email correctly' do
        expect(parser.extract_email).to eq 'ana@example.com'
      end
    end

    context 'with "Email:" pattern (no hyphen)' do
      let(:body) { "Email: ricardo@test.com\nOutros dados..." }

      it 'extracts email correctly' do
        expect(parser.extract_email).to eq 'ricardo@test.com'
      end
    end

    context 'with "E-mail de contato:" pattern' do
      let(:body) { "E-mail de contato: fernanda@example.com\nOutros dados..." }

      it 'extracts email correctly' do
        expect(parser.extract_email).to eq 'fernanda@example.com'
      end
    end

    context 'with "Email de contato:" pattern' do
      let(:body) { "Email de contato: pedro@test.com\nOutros dados..." }

      it 'extracts email correctly' do
        expect(parser.extract_email).to eq 'pedro@test.com'
      end
    end

    context 'with email containing dots and underscores' do
      let(:body) { "E-mail: first.last_name@sub.domain.com\nOutros dados..." }

      it 'extracts complex email' do
        expect(parser.extract_email).to eq 'first.last_name@sub.domain.com'
      end
    end

    context 'when email field is missing' do
      let(:body) { "Cliente: Ana\nTelefone: 11999999999" }

      it 'returns nil' do
        expect(parser.extract_email).to be_nil
      end
    end
  end

  describe '#extract_phone' do
    let(:parser) { described_class.new(build_mail_with_body(body)) }

    context 'with phone in standard format' do
      let(:body) { "Telefone: 5531977771111\nOutros dados..." }

      it 'extracts phone as digits only' do
        expect(parser.extract_phone).to eq '5531977771111'
      end
    end

    context 'with formatted phone (parentheses and dash)' do
      let(:body) { "Telefone: (55) 31 9 7777-1111\nOutros dados..." }

      it 'removes formatting and returns digits only' do
        expect(parser.extract_phone).to eq '5531977771111'
      end
    end

    context 'with country code and spaces' do
      let(:body) { "Telefone: +55 31 9 7777 1111\nOutros dados..." }

      it 'includes country code digits' do
        expect(parser.extract_phone).to eq '5531977771111'
      end
    end

    context 'with dots' do
      let(:body) { "Telefone: 55.31.97777.1111\nOutros dados..." }

      it 'removes dots' do
        expect(parser.extract_phone).to eq '5531977771111'
      end
    end

    context 'when phone field is missing' do
      let(:body) { "Cliente: Ana\nE-mail: ana@example.com" }

      it 'returns nil' do
        expect(parser.extract_phone).to be_nil
      end
    end

    context 'when phone field is empty' do
      let(:body) { "Telefone:\nCliente: Ana" }

      it 'returns nil' do
        expect(parser.extract_phone).to be_nil
      end
    end
  end

  describe '#extract_product_code' do
    context 'with "Produto:" pattern in body' do
      let(:mail) { build_mail_with_body("Produto: PROD-555\nCliente: Ana") }
      let(:parser) { described_class.new(mail) }

      it 'extracts product code from body' do
        expect(parser.extract_product_code).to eq 'PROD-555'
      end
    end

    context 'with "Produto de interesse:" pattern' do
      let(:mail) { build_mail_with_body("Produto de interesse: PROD-777\nCliente: Ricardo") }
      let(:parser) { described_class.new(mail) }

      it 'extracts product code' do
        expect(parser.extract_product_code).to eq 'PROD-777'
      end
    end

    context 'with "Código do produto:" pattern' do
      let(:mail) { build_mail_with_body("Código do produto: PROD-888\nCliente: Fernanda") }
      let(:parser) { described_class.new(mail) }

      it 'extracts product code' do
        expect(parser.extract_product_code).to eq 'PROD-888'
      end
    end

    context 'with product code in subject as fallback' do
      let(:mail) do
        Mail.new do
          from 'contato@parceiroB.com'
          to 'test@example.com'
          subject 'Pedido PROD-999'
          body 'Cliente: Pedro'
        end
      end
      let(:parser) { described_class.new(mail) }

      it 'extracts from subject when not in body' do
        expect(parser.extract_product_code).to eq 'PROD-999'
      end
    end

    context 'with lowercase product code' do
      let(:mail) { build_mail_with_body("Produto: prod-123\nCliente: Ana") }
      let(:parser) { described_class.new(mail) }

      it 'converts to uppercase' do
        expect(parser.extract_product_code).to eq 'PROD-123'
      end
    end

    context 'when no product code is found' do
      let(:mail) { build_mail_with_body("Cliente: Ana\nTelefone: 11999999999") }
      let(:parser) { described_class.new(mail) }

      it 'returns nil' do
        expect(parser.extract_product_code).to be_nil
      end
    end
  end

  # Helper methods
  def build_mail_with_body(body_text)
    Mail.new do
      from 'contato@parceiroB.com'
      to 'test@example.com'
      subject 'Test'
      body body_text
    end
  end
end
