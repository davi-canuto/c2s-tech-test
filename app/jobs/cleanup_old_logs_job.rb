class CleanupOldLogsJob < ApplicationJob
  queue_as :default

  SUCCESSFUL_RECORDS_RETENTION_DAYS = 90
  FAILED_RECORDS_RETENTION_DAYS = 180
  ORPHAN_MEDIA_RETENTION_DAYS = 365

  def perform
    cleanup_successful_parser_records
    cleanup_failed_parser_records
    cleanup_orphan_medias
    log_cleanup_summary
  end

  private

  def cleanup_successful_parser_records
    cutoff_date = SUCCESSFUL_RECORDS_RETENTION_DAYS.days.ago

    @successful_deleted = ParserRecord.kept
                                      .where(status: :success)
                                      .where("created_at < ?", cutoff_date)
                                      .count

    ParserRecord.kept
                .where(status: :success)
                .where("created_at < ?", cutoff_date)
                .find_each(&:discard)
  end

  def cleanup_failed_parser_records
    cutoff_date = FAILED_RECORDS_RETENTION_DAYS.days.ago

    @failed_deleted = ParserRecord.kept
                                  .where(status: :failed)
                                  .where("created_at < ?", cutoff_date)
                                  .count

    ParserRecord.kept
                .where(status: :failed)
                .where("created_at < ?", cutoff_date)
                .find_each(&:discard)
  end

  def cleanup_orphan_medias
    cutoff_date = ORPHAN_MEDIA_RETENTION_DAYS.days.ago

    orphan_media_ids = Media.kept
                            .left_joins(:parser_records)
                            .where("medias.created_at < ?", cutoff_date)
                            .where(parser_records: { id: nil })
                            .pluck(:id)

    @media_deleted = orphan_media_ids.count

    Media.where(id: orphan_media_ids).find_each(&:discard)
  end

  def log_cleanup_summary
    Rails.logger.info "CleanupOldLogsJob completed:"
    Rails.logger.info "  - Successful parser_records deleted: #{@successful_deleted || 0}"
    Rails.logger.info "  - Failed parser_records deleted: #{@failed_deleted || 0}"
    Rails.logger.info "  - Orphan medias deleted: #{@media_deleted || 0}"
    # can have a observability service here xD
  end
end
