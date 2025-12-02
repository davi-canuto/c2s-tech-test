class ProcessEmailJob < ApplicationJob
  queue_as :default

  def perform(parser_record_id)
    parser_record = ParserRecord.find(parser_record_id)

    return unless parser_record.status_pending?
    return unless parser_record.media&.file&.attached?

    parser_record.update!(status: :processing)

    file_content = parser_record.media.file.download

    service = ProcessEmailService.new(
      file_content,
      filename: parser_record.filename,
      parser_record: parser_record
    )
    service.call
  rescue => e
    parser_record.update!(
      status: :failed,
      error_message: "Job failed: #{e.message}"
    )
    raise
  end
end
