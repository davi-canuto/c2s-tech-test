class Customer < ApplicationRecord
  include Discard::Model

  has_many :parser_records, dependent: :nullify

  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validate :at_least_one_contact_method

  scope :recent, -> { order(created_at: :desc) }
  scope :with_email, -> { where.not(email: nil) }
  scope :with_phone, -> { where.not(phone: nil) }

  private

  def at_least_one_contact_method
    if email.blank? && phone.blank?
      errors.add(:base, :at_least_one_contact)
    end
  end
end
