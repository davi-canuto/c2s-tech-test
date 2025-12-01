require 'rails_helper'

RSpec.describe Parsers::SupplierAParser do
  describe '.can_parse?' do
    it 'returns true for emails from fornecedorA.com' do
      expect(described_class.can_parse?('loja@fornecedorA.com')).to be true
    end

    it 'returns true case insensitive' do
      expect(described_class.can_parse?('LOJA@FORNECEDORA.COM')).to be true
    end

    it 'returns false for other domains' do
      expect(described_class.can_parse?('test@example.com')).to be false
      expect(described_class.can_parse?('contato@parceiroB.com')).to be false
    end
  end

  describe '#parse' do
    context 'with email1 (complete with all fields)' do
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
    end

    context 'with email2 (complete with different format)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email2.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'extracts all information correctly' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Maria Oliveira'
        expect(result[:email]).to eq 'maria.oliveira@example.com'
        expect(result[:phone]).to eq '21998765432'
        expect(result[:product_code]).to eq 'XYZ987'
      end
    end

    context 'with email3 (valid - has email but no phone)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email3.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'succeeds because it has email (phone is optional)' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Pedro Santos'
        expect(result[:email]).to eq 'pedro.santos@example.com'
        expect(result[:phone]).to be_nil
        expect(result[:product_code]).to eq 'LMN456'
      end
    end

    context 'with email7 (incomplete - no contact info)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email7.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'returns nil because no email or phone' do
        result = parser.parse
        expect(result).to be_nil
      end

      it 'adds error about missing contact information' do
        parser.parse
        expect(parser.errors).not_to be_empty
        expect(parser.errors.first).to include('contact information')
      end
    end
  end

  describe 'extraction methods' do
    let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email1.eml')) }
    let(:mail) { Mail.read_from_string(email_file) }
    let(:parser) { described_class.new(mail) }

    describe '#extract_name' do
      it 'extracts name from pattern "Nome do cliente:"' do
        expect(parser.extract_name).to eq 'João da Silva'
      end
    end

    describe '#extract_email' do
      it 'extracts email from pattern "E-mail:"' do
        expect(parser.extract_email).to eq 'joao.silva@example.com'
      end
    end

    describe '#extract_phone' do
      it 'extracts and normalizes phone number' do
        expect(parser.extract_phone).to eq '11912345678'
      end

      it 'removes formatting characters' do
        phone = parser.extract_phone
        expect(phone).to match(/^\d+$/) # only digits
      end
    end

    describe '#extract_product_code' do
      it 'extracts product code from subject' do
        expect(parser.extract_product_code).to eq 'ABC123'
      end
    end
  end
end
