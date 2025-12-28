class Sale < ApplicationRecord
  include SubscriptionIssuer, FiscalLockable, Monetizable, Trackable, SoftDeletable

  monetize :amount

  belongs_to :member
  belongs_to :user
  belongs_to :product

  enum :payment_method, {
    cash: 1,
    credit_card: 2,
    bank_transfer: 3,
    other: 4
  }, default: :cash, validate: true

  validates :sold_on, presence: true
  validates :amount_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :member, :user, :product, presence: true
  validates :receipt_sequence, presence: true

  before_validation :snapshot_product_details
  before_validation :assign_receipt_number, on: :create

  private
    def snapshot_product_details
      return unless product.present?

      self.product_name_snapshot = product.name

      if amount_cents.nil? || amount_cents.zero?
        self.amount_cents = product.price_cents
      end

      self.receipt_sequence ||= product.accounting_category
    end

    def assign_receipt_number
      return unless cash?

      return if receipt_number.present? && receipt_year.present?

      self.receipt_year ||= sold_on&.year || Date.current.year
      if receipt_year.present? && receipt_sequence.present?
        self.receipt_number = ReceiptCounter.next_number(receipt_year, receipt_sequence)
      end
    end
end
