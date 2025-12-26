module HasAddress
  extend ActiveSupport::Concern

  included do
    normalizes :city, :address, with: ->(val) { val&.strip&.titleize }
    normalizes :zip_code, with: ->(val) { val&.strip&.gsub(/\D/, "") }
  end

  def full_address_ruby
    [ address, city, zip_code ].compact_blank.join(", ")
  end
end
