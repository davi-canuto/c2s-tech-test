class ReprocessEmailService
  include ErrorHandler

  attr_reader :parser_record, :error_message

  def initialize(media:)
    @media = media
    @parser_record = nil
    @error_message = nil
  end

  def call
    return fail_with("Media not found") unless @media.present?
    return fail_with("Media file not attached") unless @media.file.attached?

    create_parser_record
  rescue StandardError => e
    handle_error(e,
                 context: { media_id: @media&.id, filename: @media&.filename },
                 user_message: I18n.t("flash.emails.reprocess_failed", error: e.message))
  end

  def success?
    @parser_record&.persisted?
  end

  private

  def create_parser_record
    @parser_record = ParserRecord.new(
      filename: @media.filename,
      status: :pending,
      media: @media
    )

    if @parser_record.save
      self
    else
      @error_message = @parser_record.errors.full_messages.join(", ")
      nil
    end
  end

  def fail_with(message)
    @error_message = message
    nil
  end
end
