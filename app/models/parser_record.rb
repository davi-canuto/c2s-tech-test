class ParserRecord < ApplicationRecord
  belongs_to :customer, optional: true
  has_one_attached :email_file

  enum :status, {
    pending: "pending",
    processing: "processing",
    success: "success",
    failed: "failed"
  }, prefix: true

  validates :filename, presence: true
  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :successful, -> { where(status: :success) }
  scope :failed_records, -> { where(status: :failed) }
  scope :by_sender, ->(sender) { where(sender: sender) }
  scope :old_records, ->(days) { where("created_at < ?", days.days.ago) }

  def self.distinct_senders
    distinct.pluck(:sender).compact
  end

  def self.ransackable_attributes(auth_object = nil)
    %w[status sender filename parser_used created_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[customer]
  end

  before_create :set_default_status, if: -> { status.blank? }
  after_create_commit :enqueue_processing_job, if: -> { status_pending? && email_file.attached? }

  private

  def set_default_status
    self.status = :pending
  end

  def enqueue_processing_job
    ProcessEmailJob.perform_later(id)
  end
end
