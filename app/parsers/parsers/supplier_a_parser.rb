module Parsers
  class SupplierAParser < BaseParser
    SENDER_PATTERN = /@fornecedorA\.com/i

    def self.can_parse?(sender_email)
      sender_email.to_s.match?(SENDER_PATTERN)
    end

    def extract_name
      body = email_body
      match = body.match(/Nome(?:\s+do\s+cliente)?:\s*(.+)/i)
      match[1].strip if match
    end

    def extract_email
      body = email_body
      match = body.match(/E-?mail:\s*([^\s]+@[^\s]+)/i)
      match[1].strip if match
    end

    def extract_phone
      body = email_body
      match = body.match(/Telefone:\s*(.+?)(?:\n|$)/i)
      return nil unless match

      phone = match[1].gsub(/[^\d]/, '')
      phone.present? ? phone : nil
    end

    def extract_product_code
      subject = mail_object.subject
      match = subject.match(/([A-Z]{3}\d{3})/i)
      match[1].upcase if match
    end
  end
end
