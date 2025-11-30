class ProcessEmailJob < ApplicationJob
  queue_as :default

  def perform(parser_record_id)
    parser_record = ParserRecord.find(parser_record_id)

    return unless parser_record.status_pending?
    return unless parser_record.email_file.attached?

    parser_record.update!(status: :processing)
    parser_record.email_file.open do |file|
      service = ProcessEmail.new(file, filename: parser_record.filename)
      service.call

      if service.success?
        parser_record.update!(
          status: :success,
          sender: service.parser_record.sender,
          parser_used: service.parser_record.parser_used,
          extracted_data: service.parser_record.extracted_data,
          customer: service.customer
        )
      else
        parser_record.update!(
          status: :failed,
          error_message: service.parser_record&.error_message || "Unknown error"
        )
      end
    end
  rescue => e
    parser_record.update!(
      status: :failed,
      error_message: "Job failed: #{e.message}"
    )
    raise
  end
end
