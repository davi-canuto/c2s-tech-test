# Shared examples for parser behavior

RSpec.shared_examples 'a parser' do |domain_pattern|
  describe '.can_parse?' do
    it 'implements the can_parse? class method' do
      expect(described_class).to respond_to(:can_parse?)
    end

    it 'returns boolean' do
      result = described_class.can_parse?('test@example.com')
      expect(result).to be_in([ true, false ])
    end

    it 'handles nil gracefully' do
      expect { described_class.can_parse?(nil) }.not_to raise_error
      expect(described_class.can_parse?(nil)).to be false
    end

    it 'handles empty string gracefully' do
      expect { described_class.can_parse?('') }.not_to raise_error
      expect(described_class.can_parse?('')).to be false
    end
  end

  describe '#parse' do
    it 'implements the parse instance method' do
      mail = Mail.new { body 'test' }
      parser = described_class.new(mail)
      expect(parser).to respond_to(:parse)
    end

    it 'returns hash or nil' do
      mail = Mail.new { body 'test' }
      parser = described_class.new(mail)
      result = parser.parse

      expect(result).to be_a(Hash).or be_nil
    end

    it 'returns hash with symbol keys when successful' do
      mail = Mail.new { body 'test' }
      parser = described_class.new(mail)
      result = parser.parse

      if result
        expect(result.keys).to all(be_a(Symbol))
      end
    end
  end

  describe '#errors' do
    it 'implements the errors method' do
      mail = Mail.new { body 'test' }
      parser = described_class.new(mail)
      expect(parser).to respond_to(:errors)
    end

    it 'returns an array' do
      mail = Mail.new { body 'test' }
      parser = described_class.new(mail)
      parser.parse
      expect(parser.errors).to be_an(Array)
    end
  end

  describe 'extraction methods' do
    let(:mail) { Mail.new { body 'test' } }
    let(:parser) { described_class.new(mail) }

    it 'implements extract_name' do
      expect(parser).to respond_to(:extract_name)
    end

    it 'implements extract_email' do
      expect(parser).to respond_to(:extract_email)
    end

    it 'implements extract_phone' do
      expect(parser).to respond_to(:extract_phone)
    end

    it 'implements extract_product_code' do
      expect(parser).to respond_to(:extract_product_code)
    end
  end
end

RSpec.shared_examples 'parser with contact validation' do
  context 'when neither email nor phone is present' do
    let(:parser) { described_class.new(mail_without_contacts) }

    it 'returns nil' do
      expect(parser.parse).to be_nil
    end

    it 'adds error about missing contact' do
      parser.parse
      expect(parser.errors).not_to be_empty
      expect(parser.errors.join).to match(/contact/i)
    end
  end

  context 'when only email is present' do
    let(:parser) { described_class.new(mail_with_only_email) }

    it 'succeeds' do
      expect(parser.parse).to be_a(Hash)
    end

    it 'includes email in result' do
      result = parser.parse
      expect(result[:email]).to be_present
      expect(result[:phone]).to be_nil
    end
  end

  context 'when only phone is present' do
    let(:parser) { described_class.new(mail_with_only_phone) }

    it 'succeeds' do
      expect(parser.parse).to be_a(Hash)
    end

    it 'includes phone in result' do
      result = parser.parse
      expect(result[:phone]).to be_present
      expect(result[:email]).to be_nil
    end
  end
end

RSpec.shared_examples 'parser with name extraction' do
  context 'name extraction edge cases' do
    it 'handles names with accents' do
      mail = build_test_mail("Nome: José María Gonçalves")
      parser = described_class.new(mail)

      expect(parser.extract_name).to eq 'José María Gonçalves'
    end

    it 'handles names with hyphens' do
      mail = build_test_mail("Nome: Ana-Maria Santos-Silva")
      parser = described_class.new(mail)

      expect(parser.extract_name).to eq 'Ana-Maria Santos-Silva'
    end

    it 'strips extra whitespace' do
      mail = build_test_mail("Nome:    Pedro Silva   ")
      parser = described_class.new(mail)

      expect(parser.extract_name).to eq 'Pedro Silva'
    end

    it 'returns nil when name is not found' do
      mail = build_test_mail("Email: test@example.com")
      parser = described_class.new(mail)

      expect(parser.extract_name).to be_nil
    end
  end
end

RSpec.shared_examples 'parser with phone normalization' do
  context 'phone number normalization' do
    it 'removes parentheses' do
      mail = build_test_mail("Telefone: (11) 91234-5678")
      parser = described_class.new(mail)

      phone = parser.extract_phone
      expect(phone).not_to include('(', ')')
      expect(phone).to match(/^\d+$/)
    end

    it 'removes dashes' do
      mail = build_test_mail("Telefone: 11-91234-5678")
      parser = described_class.new(mail)

      phone = parser.extract_phone
      expect(phone).not_to include('-')
      expect(phone).to match(/^\d+$/)
    end

    it 'removes spaces' do
      mail = build_test_mail("Telefone: 11 9 1234 5678")
      parser = described_class.new(mail)

      phone = parser.extract_phone
      expect(phone).not_to include(' ')
      expect(phone).to match(/^\d+$/)
    end

    it 'removes dots' do
      mail = build_test_mail("Telefone: 11.91234.5678")
      parser = described_class.new(mail)

      phone = parser.extract_phone
      expect(phone).not_to include('.')
      expect(phone).to match(/^\d+$/)
    end

    it 'returns nil for empty phone field' do
      mail = build_test_mail("Telefone: ")
      parser = described_class.new(mail)

      expect(parser.extract_phone).to be_nil
    end

    it 'returns nil when phone contains only non-digits' do
      mail = build_test_mail("Telefone: ---")
      parser = described_class.new(mail)

      expect(parser.extract_phone).to be_nil
    end
  end
end

def build_test_mail(body_text)
  Mail.new do
    from 'test@example.com'
    to 'receiver@example.com'
    subject 'Test'
    body body_text
  end
end
