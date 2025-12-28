class Subscription < ApplicationRecord
  include SoftDeletable, DateRangeable

  belongs_to :member
  belongs_to :product
  belongs_to :sale, inverse_of: :subscription

  validates :member, :product, :sale, presence: true

  before_validation :calculate_dates_via_duration, on: :create

  after_discard :discard_parent_sale
  after_undiscard :undiscard_parent_sale

  private
    def calculate_dates_via_duration
      return if start_date.present? && end_date.present?

      return unless product.present?

      reference_date = start_date || sale&.sold_on || Date.current
      result = Duration.new(product, reference_date).calculate

      self.start_date = result[:start_date]
      self.end_date   = result[:end_date]
    end

    def discard_parent_sale
      if sale.present? && !sale.discarded?
        sale.discard!
      end
    end

    def undiscard_parent_sale
      if sale.present? && sale.discarded?
        sale.undiscard!
      end
    end
end
