class UploadEmailService
  include ErrorHandler

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
    return fail_with(:file_too_large, max_size: "10MB") unless valid_size?

    create_record_with_attachment
  rescue StandardError => e
    handle_error(e,
                 context: { filename: @file&.original_filename },
                 user_message: I18n.t("flash.emails.upload_failed", errors: e.message))
  end

  def success?
    @parser_record&.persisted?
  end

  private

  def valid_extension?
    @file.original_filename.end_with?(".eml")
  end

  def valid_size?
    @file.size <= MAX_FILE_SIZE
  end

  def create_record_with_attachment
    ActiveRecord::Base.transaction do
      media = create_media_record
      return nil unless media

      @parser_record = ParserRecord.new(
        filename: @file.original_filename,
        status: :pending,
        media:
      )

      if @parser_record.save
        self
      else
        @error_message = @parser_record.errors.full_messages.join(", ")
        raise ActiveRecord::Rollback
      end
    end
  end

  def create_media_record
    content = @file.read
    checksum = Digest::MD5.hexdigest(content)
    @file.rewind

    media = Media.new(
      filename: @file.original_filename,
      file_size: @file.size,
      content_type: @file.content_type || "message/rfc822",
      checksum: checksum
    )

    media.file.attach(
      io: @file.open,
      filename: @file.original_filename,
      content_type: @file.content_type || "message/rfc822"
    )

    if media.save
      media
    else
      @error_message = media.errors.full_messages.join(", ")
      nil
    end
  rescue StandardError => e
    log_error(e, context: { filename: @file.original_filename, step: "media_creation" })
    raise
  end

  def fail_with(key, **options)
    @error_message = I18n.t("flash.emails.#{key}", **options)
    nil
  end
end
