class UploadEmailService
  MAX_FILE_SIZE = 10.megabytes

  attr_reader :parser_record, :error_message

  def initialize(params)
    @file = params[:email_file]
    @parser_record = nil
    @error_message = nil
  end

  def call
    return fail_with(:file_required) unless @file.present?
    return fail_with(:invalid_format) unless valid_extension?
    return fail_with(:file_too_large, max_size: '10MB') unless valid_size?

    create_record_with_attachment
  end

  def success?
    @parser_record&.persisted?
  end

  private

  def valid_extension?
    @file.original_filename.end_with?('.eml')
  end

  def valid_size?
    @file.size <= MAX_FILE_SIZE
  end

  def create_record_with_attachment
    @parser_record = ParserRecord.new(
      filename: @file.original_filename,
      status: :pending
    )

    @parser_record.email_file.attach(
      io: @file.open,
      filename: @file.original_filename,
      content_type: @file.content_type
    )

    if @parser_record.save
      self
    else
      @error_message = I18n.t('flash.emails.upload_failed',
                              errors: @parser_record.errors.full_messages.join(', '))
      nil
    end
  end

  def fail_with(key, **options)
    @error_message = I18n.t("flash.emails.#{key}", **options)
    nil
  end
end
