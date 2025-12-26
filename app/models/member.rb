class Member < ApplicationRecord
  include SoftDeletable, Personable, HasAddress

  normalizes :fiscal_code, with: ->(c) { c.strip.upcase }

  validates :birth_date, presence: true
  validates :fiscal_code,
            presence: true,
            uniqueness: { conditions: -> { kept } },
            format: { with: /\A[A-Z0-9]{16}\z/, message: "must be 16 alphanumeric characters" }

  validates :phone, phone: { possible: true, allow_blank: true, types: [ :mobile, :fixed_line ] }

  has_many :sales, dependent: :restrict_with_error
  has_many :access_logs, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :memberships, -> { joins(:product).merge(Product.associative) },
           class_name: "Subscription"

  def medical_certificate_valid?(date = Date.today)
    return false if medical_certificate_expiry.nil?

    medical_certificate_expiry >= date
  end

  def membership_expiry_date
    memberships.kept.maximum(:end_date)
  end

  def membership_valid?(date = Date.today)
    expiry = membership_expiry_date
    return false if expiry.nil?

    expiry >= date
  end

  def compliant?(date = Date.today)
    medical_certificate_valid?(date) && membership_valid?(date)
  end

  def status_label
    return "error" if discarded?
    return "warning" unless compliant?
    "success"
  end
end
