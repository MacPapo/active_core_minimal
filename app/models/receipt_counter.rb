class ReceiptCounter < ApplicationRecord
  validates :year, :sequence_category, presence: true

  def self.next_number(year, category)
    transaction do
      counter = lock.find_or_create_by!(year: year, sequence_category: category)
      counter.increment!(:last_number)

      counter.last_number
    end
  end
end
