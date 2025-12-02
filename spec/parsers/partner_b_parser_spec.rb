require 'rails_helper'

RSpec.describe PartnerBParser do
  describe '.can_parse?' do
    it 'returns true for emails from parceiroB.com' do
      expect(described_class.can_parse?('contato@parceiroB.com')).to be true
    end

    it 'returns true case insensitive' do
      expect(described_class.can_parse?('CONTATO@PARCEIROB.COM')).to be true
    end

    it 'returns false for other domains' do
      expect(described_class.can_parse?('test@example.com')).to be false
      expect(described_class.can_parse?('loja@fornecedorA.com')).to be false
    end
  end

  describe '#parse' do
    context 'with email4 (complete with all fields)' do
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
    end

    context 'with email5 (complete with different format)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email5.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'extracts all information correctly' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Ricardo Almeida'
        expect(result[:email]).to eq 'ricardo.almeida@example.com'
        expect(result[:phone]).to eq '41988882222'
        expect(result[:product_code]).to eq 'PROD-888'
      end
    end

    context 'with email6 (valid - has phone but no email)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email6.eml')) }
      let(:mail) { Mail.read_from_string(email_file) }
      let(:parser) { described_class.new(mail) }

      it 'succeeds because it has phone (email is optional)' do
        result = parser.parse

        expect(result).not_to be_nil
        expect(result[:name]).to eq 'Fernanda Lima'
        expect(result[:email]).to be_nil
        expect(result[:phone]).to eq '61933334444'
        expect(result[:product_code]).to eq 'PROD-999'
      end
    end

    context 'with email8 (incomplete - no contact info)' do
      let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email8.eml')) }
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
    let(:email_file) { File.read(Rails.root.join('spec/fixtures/emails/email4.eml')) }
    let(:mail) { Mail.read_from_string(email_file) }
    let(:parser) { described_class.new(mail) }

    describe '#extract_name' do
      it 'extracts name from pattern "Cliente:"' do
        expect(parser.extract_name).to eq 'Ana Costa'
      end
    end

    describe '#extract_email' do
      it 'extracts email from pattern "Email:"' do
        expect(parser.extract_email).to eq 'ana.costa@example.com'
      end
    end

    describe '#extract_phone' do
      it 'extracts and normalizes phone number' do
        expect(parser.extract_phone).to eq '5531977771111'
      end

      it 'removes formatting characters' do
        phone = parser.extract_phone
        expect(phone).to match(/^\d+$/) # only digits
      end
    end

    describe '#extract_product_code' do
      it 'extracts product code from pattern "Produto de interesse:"' do
        expect(parser.extract_product_code).to eq 'PROD-555'
      end
    end
  end
end
