class ParserRecord < ApplicationRecord
  include Discard::Model

  belongs_to :customer, optional: true
  belongs_to :media, optional: true
  has_one_attached :email_file

  enum :status, {
    pending: 0,
    processing: 1,
    success: 2,
    failed: 3
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
    %w[customer media]
  end

  after_create_commit :enqueue_processing_job, if: :has_file_and_pending?

  private

  def has_file_and_pending?
    self.status_pending? && self.media&.file&.attached?
  end

  def enqueue_processing_job
    ProcessEmailJob.perform_later(id)
  end
end
