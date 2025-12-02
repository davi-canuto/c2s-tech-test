class PartnerBParser < BaseParser
  SENDER_PATTERN = /@(?:[a-zA-Z0-9-]+\.)*parceiroB\.com$/i

  def self.can_parse?(sender_email)
    sender_email.to_s.match?(SENDER_PATTERN)
  end

  def extract_name
    body = email_body
    match = body.match(/^(?:Nome\s+completo|Nome\s+do\s+cliente|Cliente|Nome):\s*(.+)$/i)
    match[1].strip if match
  end

  def extract_email
    body = email_body
    match = body.match(/E-?mail(?:\s+de\s+contato)?:\s*([^\s]+@[^\s]+)/i)
    match[1].strip if match
  end

  def extract_phone
    body = email_body
    match = body.match(/Telefone:\s*(.+?)(?:\n|$)/i)
    return nil unless match

    phone = match[1].gsub(/[^\d]/, "")
    phone.present? ? phone : nil
  end

  def extract_product_code
    body = email_body
    match = body.match(/(?:Produto(?:\s+de\s+interesse)?|Código\s+do\s+produto):\s*([A-Z0-9\-]+)/i)
    return match[1].strip.upcase if match

    subject = mail_object.subject
    match = subject.match(/(PROD-\d{3})/i)
    match[1].upcase if match
  end
end
