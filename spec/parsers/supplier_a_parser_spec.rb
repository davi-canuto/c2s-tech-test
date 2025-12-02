require 'rails_helper'

RSpec.describe SupplierAParser do
  describe '.can_parse?' do
    context 'when email is from fornecedorA.com' do
      it 'returns true for standard format' do
        expect(described_class.can_parse?('loja@fornecedorA.com')).to be true
      end

      it 'returns true case insensitive' do
        expect(described_class.can_parse?('LOJA@FORNECEDORA.COM')).to be true
        expect(described_class.can_parse?('Loja@FornecedorA.Com')).to be true
      end

      it 'returns true with different subdomains' do
        expect(described_class.can_parse?('vendas@fornecedorA.com')).to be true
        expect(described_class.can_parse?('suporte@fornecedorA.com')).to be true
      end

      it 'returns true with subdomain' do
        expect(described_class.can_parse?('loja@shop.fornecedorA.com')).to be true
      end
    end

    context 'when email is NOT from fornecedorA.com' do
      it 'returns false for other domains' do
        expect(described_class.can_parse?('test@example.com')).to be false
        expect(described_class.can_parse?('contato@parceiroB.com')).to be false
      end

      it 'returns false for similar but different domains' do
        expect(described_class.can_parse?('loja@fornecedorA.com.br')).to be false
        expect(described_class.can_parse?('loja@fornecedorB.com')).to be false
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
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email1.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'extracts all information correctly' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'João da Silva'
        expect(result[:email]).to eq 'joao.silva@example.com'
        expect(result[:phone]).to eq '11912345678'
        expect(result[:product_code]).to eq 'ABC123'
        expect(result[:sender]).to eq 'loja@fornecedorA.com'
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

    context 'with valid email but no phone' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email3.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'succeeds because email is present (phone is optional)' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Pedro Santos'
        expect(result[:email]).to eq 'pedro.santos@example.com'
        expect(result[:phone]).to be_nil
        expect(result[:product_code]).to eq 'LMN456'
      end
    end

    context 'with missing required contact information' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email7.eml')) }
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
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email1.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'returns consistent results' do
        result1 = parser.parse
        result2 = parser.parse

        expect(result1).to eq(result2)
      end

      it 'clears previous errors' do
        parser.parse
        first_errors = parser.errors.dup
        parser.parse

        expect(parser.errors).to eq(first_errors)
      end
    end
  end

  describe '#extract_name' do
    let(:parser) { described_class.new(build_mail_with_body(body)) }

    context 'with standard pattern' do
      let(:body) { "Nome do cliente: João da Silva\nOutros dados..." }

      it 'extracts name correctly' do
        expect(parser.extract_name).to eq 'João da Silva'
      end
    end

    context 'with simplified pattern' do
      let(:body) { "Nome: Maria Santos\nOutros dados..." }

      it 'extracts name correctly' do
        expect(parser.extract_name).to eq 'Maria Santos'
      end
    end

    context 'with name containing special characters' do
      let(:body) { "Nome: José de Souza-Oliveira\nOutros dados..." }

      it 'extracts name with hyphens' do
        expect(parser.extract_name).to eq 'José de Souza-Oliveira'
      end
    end

    context 'with name containing accents' do
      let(:body) { "Nome: André Gonçalves Müller\nOutros dados..." }

      it 'extracts name with accents' do
        expect(parser.extract_name).to eq 'André Gonçalves Müller'
      end
    end

    context 'with extra whitespace' do
      let(:body) { "Nome:    Pedro Silva   \nOutros dados..." }

      it 'strips extra whitespace' do
        expect(parser.extract_name).to eq 'Pedro Silva'
      end
    end

    context 'when name field is missing' do
      let(:body) { "Email: test@example.com\nTelefone: 11999999999" }

      it 'returns nil' do
        expect(parser.extract_name).to be_nil
      end
    end

    context 'when name field is empty' do
      let(:body) { "Nome:\nEmail: test@example.com" }

      it 'returns nil' do
        expect(parser.extract_name).to be_nil
      end
    end
  end

  describe '#extract_email' do
    let(:parser) { described_class.new(build_mail_with_body(body)) }

    context 'with standard pattern' do
      let(:body) { "E-mail: joao@example.com\nOutros dados..." }

      it 'extracts email correctly' do
        expect(parser.extract_email).to eq 'joao@example.com'
      end
    end

    context 'with alternate pattern (no hyphen)' do
      let(:body) { "Email: maria@test.com\nOutros dados..." }

      it 'extracts email correctly' do
        expect(parser.extract_email).to eq 'maria@test.com'
      end
    end

    context 'with uppercase email' do
      let(:body) { "E-mail: PEDRO@EXAMPLE.COM\nOutros dados..." }

      it 'extracts email as-is (case preserved)' do
        expect(parser.extract_email).to eq 'PEDRO@EXAMPLE.COM'
      end
    end

    context 'with email containing dots and underscores' do
      let(:body) { "E-mail: first.last_name@sub.domain.com\nOutros dados..." }

      it 'extracts complex email' do
        expect(parser.extract_email).to eq 'first.last_name@sub.domain.com'
      end
    end

    context 'when email field is missing' do
      let(:body) { "Nome: João\nTelefone: 11999999999" }

      it 'returns nil' do
        expect(parser.extract_email).to be_nil
      end
    end

    context 'when email is malformed' do
      let(:body) { "E-mail: notanemail\nOutros dados..." }

      it 'does not match' do
        expect(parser.extract_email).to be_nil
      end
    end
  end

  describe '#extract_phone' do
    let(:parser) { described_class.new(build_mail_with_body(body)) }

    context 'with phone in standard format' do
      let(:body) { "Telefone: 11912345678\nOutros dados..." }

      it 'extracts phone as digits only' do
        expect(parser.extract_phone).to eq '11912345678'
      end
    end

    context 'with formatted phone (parentheses and dash)' do
      let(:body) { "Telefone: (11) 91234-5678\nOutros dados..." }

      it 'removes formatting and returns digits only' do
        expect(parser.extract_phone).to eq '11912345678'
      end
    end

    context 'with country code' do
      let(:body) { "Telefone: +55 11 91234-5678\nOutros dados..." }

      it 'includes country code digits' do
        expect(parser.extract_phone).to eq '5511912345678'
      end
    end

    context 'with spaces' do
      let(:body) { "Telefone: 11 9 1234 5678\nOutros dados..." }

      it 'removes spaces' do
        expect(parser.extract_phone).to eq '11912345678'
      end
    end

    context 'with dots' do
      let(:body) { "Telefone: 11.91234.5678\nOutros dados..." }

      it 'removes dots' do
        expect(parser.extract_phone).to eq '11912345678'
      end
    end

    context 'when phone field is missing' do
      let(:body) { "Nome: João\nE-mail: joao@example.com" }

      it 'returns nil' do
        expect(parser.extract_phone).to be_nil
      end
    end

    context 'when phone field is empty' do
      let(:body) { "Telefone:\nNome: João" }

      it 'returns nil' do
        expect(parser.extract_phone).to be_nil
      end
    end

    context 'when phone contains only non-digit characters' do
      let(:body) { "Telefone: ---\nNome: João" }

      it 'returns nil' do
        expect(parser.extract_phone).to be_nil
      end
    end
  end

  describe '#extract_product_code' do
    context 'with standard product code in subject' do
      let(:mail) { build_mail_with_subject('Pedido: ABC123') }
      let(:parser) { described_class.new(mail) }

      it 'extracts product code' do
        expect(parser.extract_product_code).to eq 'ABC123'
      end
    end

    context 'with lowercase product code' do
      let(:mail) { build_mail_with_subject('Pedido: xyz987') }
      let(:parser) { described_class.new(mail) }

      it 'converts to uppercase' do
        expect(parser.extract_product_code).to eq 'XYZ987'
      end
    end

    context 'with multiple codes in subject' do
      let(:mail) { build_mail_with_subject('Pedidos: ABC123 e XYZ456') }
      let(:parser) { described_class.new(mail) }

      it 'extracts first matching code' do
        expect(parser.extract_product_code).to eq 'ABC123'
      end
    end

    context 'when no product code in subject' do
      let(:mail) { build_mail_with_subject('Contato geral') }
      let(:parser) { described_class.new(mail) }

      it 'returns nil' do
        expect(parser.extract_product_code).to be_nil
      end
    end

    context 'when subject is empty' do
      let(:mail) { build_mail_with_subject('') }
      let(:parser) { described_class.new(mail) }

      it 'returns nil' do
        expect(parser.extract_product_code).to be_nil
      end
    end
  end

  # Helper methods
  def build_mail_with_body(body_text)
    Mail.new do
      from 'loja@fornecedorA.com'
      to 'test@example.com'
      subject 'Test'
      body body_text
    end
  end

  def build_mail_with_subject(subject_text)
    Mail.new do
      from 'loja@fornecedorA.com'
      to 'test@example.com'
      subject subject_text
      body 'Test body'
    end
  end
end
