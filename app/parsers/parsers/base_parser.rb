module Parsers
  class BaseParser
    attr_reader :mail_object, :errors

    def initialize(mail_object)
      @mail_object = mail_object
      @errors = []
    end

    def parse
      return nil unless valid_email?

      data = {
        name: extract_name,
        email: extract_email,
        phone: extract_phone,
        product_code: extract_product_code,
        subject: mail_object.subject,
        sender: mail_object.from&.first
      }

      validate_extracted_data(data)
      data
    rescue StandardError => e
      @errors << e.message
      nil
    end

    # Abstract methods
    def extract_name
      raise NotImplementedError, "#{self.class} must implement #extract_name"
    end

    def extract_email
      raise NotImplementedError, "#{self.class} must implement #extract_email"
    end

    def extract_phone
      raise NotImplementedError, "#{self.class} must implement #extract_phone"
    end

    def extract_product_code
      raise NotImplementedError, "#{self.class} must implement #extract_product_code"
    end

    def self.can_parse?(sender_email)
      raise NotImplementedError, "#{self} must implement .can_parse?"
    end

    private

    def valid_email?
      mail_object.present? && email_body.present?
    end

    def validate_extracted_data(data)
      if data[:email].blank? && data[:phone].blank?
        @errors << "No contact information found (email or phone required)"
        raise StandardError, "Validation failed: no contact information"
      end
    end

    def email_body
      @email_body ||= begin
        if mail_object.multipart?
          mail_object.text_part&.decoded || mail_object.html_part&.decoded
        else
          mail_object.body.decoded
        end
      end
    end
  end
end
