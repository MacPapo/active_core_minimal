class Discipline < ApplicationRecord
  include SoftDeletable

  has_many :product_disciplines, dependent: :destroy
  has_many :products, through: :product_disciplines

  normalizes :name, with: ->(n) { n.squish.titleize }

  validates :name, presence: true, uniqueness: { conditions: -> { kept } }

  broadcasts_refreshes
end
