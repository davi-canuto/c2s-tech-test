class Media < ApplicationRecord
  self.table_name = "medias"

  has_one_attached :file
  has_many :parser_records, dependent: :nullify

  validates :filename, presence: true
  validates :file_size, presence: true, numericality: { greater_than: 0 }
  validates :content_type, presence: true
  validates :checksum, presence: true, uniqueness: { message: :file_already_exists }

  scope :recent, -> { order(created_at: :desc) }
  scope :by_sender, ->(sender) { where(sender: sender) }
  scope :old_files, ->(days) { where("created_at < ?", days.days.ago) }

  def self.ransackable_attributes(auth_object = nil)
    %w[filename sender subject original_date created_at]
  end
end
