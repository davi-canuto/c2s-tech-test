class ProcessEmail
  include ErrorHandler

  attr_reader :parser_record, :customer

  def initialize(email_file, filename: nil)
    @email_file = email_file
    @filename = filename || extract_filename
    @parser_record = nil
    @customer = nil
  end

  def call
    mail = parse_mail
    return log_failure("Invalid email file") unless mail

    sender = extract_sender(mail)
    return log_failure("No sender found", sender: "unknown") unless sender

    parser_class = find_parser(sender)
    return log_failure("No parser found for: #{sender}", sender: sender) unless parser_class

    extracted_data = extract_data(parser_class, mail)
    return log_failure_with_parser(parser_class, sender, extracted_data) unless extracted_data

    create_customer_and_log(extracted_data, sender, parser_class, mail)
  rescue Mail::Field::ParseError => e
    handle_error(e, context: { filename: @filename, step: "mail_parsing" })
    log_failure("Email format error: #{e.message}")
  rescue StandardError => e
    handle_error(e, context: { filename: @filename, step: "email_processing" })
    log_failure("Unexpected error: #{e.message}")
  end

  def success?
    @parser_record&.status_success? && @customer&.persisted?
  end

  private

  def parse_mail
    content = extract_content(@email_file)
    return nil unless content

    Mail.read_from_string(content)
  rescue Mail::Field::ParseError => e
    log_error(e, context: { filename: @filename })
    raise
  rescue StandardError => e
    log_error(e, context: { filename: @filename, step: "mail_reading" })
    nil
  end

  def extract_content(file)
    if file.respond_to?(:read)
      file.read
    elsif file.is_a?(String)
      file
    end
  end

  def extract_filename
    @email_file.respond_to?(:original_filename) ? @email_file.original_filename : "email.eml"
  end

  def extract_sender(mail)
    mail.from&.first
  end

  def find_parser(sender)
    Parsers::ParserRegistry.find_parser_for(sender)
  end

  def extract_data(parser_class, mail)
    parser = parser_class.new(mail)
    data = parser.parse

    @parser_errors = parser.errors unless data
    data
  end

  def create_customer_and_log(data, sender, parser_class, mail)
    @customer = CreateCustomer.new(data).call

    unless @customer
      return log_failure(
        "Failed to create customer",
        sender: sender,
        parser: parser_class.name,
        data: data
      )
    end

    log_success(
      sender: sender,
      parser: parser_class.name,
      data: data,
      customer: @customer
    )

    @customer
  end

  def log_success(sender:, parser:, data:, customer:)
    @parser_record = create_parser_record(
      filename: @filename,
      sender: sender,
      parser_used: parser,
      status: :success,
      extracted_data: data,
      customer: customer
    )

    attach_file_to_record
    @parser_record
  end

  def log_failure(error, sender: "unknown", parser: nil, data: nil)
    @parser_record = create_parser_record(
      filename: @filename,
      sender: sender,
      parser_used: parser,
      status: :failed,
      error_message: error,
      extracted_data: data || {}
    )

    attach_file_to_record
    nil
  end

  def log_failure_with_parser(parser_class, sender, extracted_data)
    error = @parser_errors&.join(", ") || "Failed to parse email"
    log_failure(
      error,
      sender: sender,
      parser: parser_class.name,
      data: extracted_data || {}
    )
  end

  def create_parser_record(**attributes)
    ParserRecord.create!(attributes)
  rescue ActiveRecord::RecordInvalid => e
    log_error(e, context: { attributes: attributes, step: "parser_record_creation" })
    # Fallback: create without raising
    ParserRecord.create(attributes.merge(error_message: "Record creation failed: #{e.message}"))
  rescue StandardError => e
    log_error(e, context: { attributes: attributes, step: "parser_record_creation" })
    nil
  end

  def attach_file_to_record
    return unless @parser_record && @email_file

    io = prepare_io_for_attachment
    return unless io

    @parser_record.email_file.attach(
      io: io,
      filename: @filename,
      content_type: "message/rfc822"
    )
  rescue StandardError => e
    log_error(e, context: { filename: @filename, step: "file_attachment" })
  end

  def prepare_io_for_attachment
    if @email_file.respond_to?(:tempfile)
      @email_file.tempfile
    elsif @email_file.respond_to?(:read)
      @email_file.rewind if @email_file.respond_to?(:rewind)
      StringIO.new(@email_file.read)
    end
  rescue StandardError => e
    log_error(e, context: { filename: @filename, step: "io_preparation" })
    nil
  end
end
