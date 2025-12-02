class ProcessEmailService
  include ErrorHandler

  attr_reader :parser_record, :customer

  def initialize(email_file, filename: nil, parser_record: nil)
    @email_file = email_file
    @filename = filename || extract_filename_from_file(email_file)
    @parser_record = parser_record
    @customer = nil
  end

  def call
    mail = parse_mail
    return log_failure("Invalid email file") unless mail

    sender = extract_sender(mail)
    return log_failure("No sender found") unless sender

    parser_klass = find_parser(sender)
    return log_failure("No parser found for: #{sender}", sender:) unless parser_klass

    extracted_data = extract_data(parser_klass, mail)
    unless extracted_data
      error_msg = @parser_errors&.any? ? @parser_errors.join(", ") : nil
      error_msg ||= "No data for extract for parser: #{sender}"

      return log_failure(
        error_msg,
        parser: parser_klass.name,
        sender:
      )
    end

    create_customer_and_log(extracted_data, sender, parser_klass, mail)
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

  def extract_sender(mail)
    mail.from&.first
  end

  def find_parser(sender)
    ParserRegistry.find_parser_for(sender)
  end

  def extract_data(parser_klass, mail)
    parser = parser_klass.new(mail)
    data = parser.parse

    @parser_errors = parser.errors unless data
    data
  end

  def create_customer_and_log(data, sender, parser_klass, mail)
    @customer = CreateCustomerService.new(data).call

    unless @customer
      return log_failure(
        "Failed to create customer",
        sender:,
        parser: parser_klass.name,
        data:
      )
    end

    log_success(
      sender:,
      data:,
      mail:,
      parser: parser_klass.name,
      customer: @customer
    )

    @customer
  end

  def log_success(error: nil, sender:, parser:, data:, customer:, mail:)
    logging(
      status: :success,
      error:,
      parser:,
      data:,
      sender:,
      customer:,
      mail:
    )
  end

  def log_failure(error, sender: "unknown", parser: nil, data: {}, customer: nil, mail: nil)
    logging(
      status: :failed,
      error:,
      parser:,
      data:,
      sender:,
      customer:,
      mail:
    )
  end

  def logging(status:, error:, sender:, parser:, data:, customer:, mail:)
    @parser_record = create_parser_record(
      status:,
      error_message: error,
      filename: @filename,
      sender:,
      customer:,
      parser_used: parser,
      extracted_data: data
    )

    return nil if @parser_record.status_failed?
    update_media_metadata(mail, sender)
    @parser_record
  end

  def create_parser_record(**attributes)
    if @parser_record
      @parser_record.update!(attributes)
      @parser_record
    else
      ParserRecord.create!(attributes)
    end
  rescue => e
    if @parser_record
      @parser_record.update(
        attributes.merge(
          error_message: "Record update failed: #{e.message}"
        )
      )
      @parser_record
    else
      ParserRecord.create(
        attributes.merge(
          error_message: "Record creation failed: #{e.message}"
        )
      )
    end
    log_error(e, context: { attributes: attributes, step: "parser_record_creation" })
  end

  def update_media_metadata(mail, sender)
    return unless @parser_record&.media

    @parser_record.media.update(
      sender:,
      subject: mail.subject,
      original_date: mail.date
    )
  rescue => e
    log_error(e, context: { filename: @filename, step: "media_metadata_update" })
  end

  def extract_filename_from_file(file)
    if file.respond_to?(:original_filename)
      file.original_filename
    elsif file.respond_to?(:path)
      File.basename(file.path)
    else
      "email.eml"
    end
  end
end
