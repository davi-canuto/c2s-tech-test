require "sidekiq/cron"

Sidekiq::Cron::Job.create(
  name: "Cleanup Old Logs - Daily",
  cron: "0 2 * * *",
  class: "CleanupOldLogsJob",
  queue: "default",
  description: "Soft deletes old parser_records and orphan medias based on retention policies"
)

Rails.logger.info "Sidekiq-cron jobs loaded successfully"
