class Member < ApplicationRecord
  include Filterable, SoftDeletable, Personable, HasAddress, Avatarable

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

  def relevant_subscriptions
    source = subscriptions.loaded? ? subscriptions : subscriptions.includes(:product)
    active_source = source.select { |sub| sub.kept? }

    sorted = active_source.sort_by(&:end_date).reverse

    latest_per_product = sorted.uniq(&:product_id)

    cutoff_date = 60.days.ago.to_date
    visible = latest_per_product.select do |sub|
      sub.end_date >= cutoff_date
    end

    visible.sort_by { |sub| (sub.end_date - Date.current).to_i }
  end

  def renewal_info_for(product)
    dates = RenewalCalculator.new(self, product, Date.current).call

    last_sub = subscriptions.kept.where(product: product).order(end_date: :desc).first
    dates.merge(last_subscription_end: last_sub&.end_date)
  end

  def self.available_filters
    [
      { key: :query, label: "Cerca (Nome, CF, Email)" },
      {
        key: :med_cert,
        label: "Certificato Medico",
        options: [
          [ "Valido", "valid" ],
          [ "Scaduto", "expired" ],
          [ "Mancante", "missing" ]
        ]
      },
      {
        key: :state,
        label: "Archivio",
        options: [
          [ "Attivi", "active" ],
          [ "Archiviati", "archived" ]
        ]
      }
    ]
  end

  scope :search_by_text, ->(text) {
    term = "%#{text.strip}%"
    where(
      "full_name LIKE :term OR fiscal_code LIKE :upcase_term OR email_address LIKE :term",
      term: term,
      upcase_term: term.upcase
    )
  }

  scope :filter_by_med_cert, ->(val) {
    case val
    when "valid"   then where("medical_certificate_expiry >= ?", Date.current)
    when "expired" then where("medical_certificate_expiry < ?", Date.current)
    when "missing" then where(medical_certificate_expiry: nil)
    end
  }

  scope :filter_by_state, ->(val) {
    val == "archived" ? discarded : kept
  }
end
