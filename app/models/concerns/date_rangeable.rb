module DateRangeable
  extend ActiveSupport::Concern

  included do
    scope :active_at, ->(date) { where("start_date <= ? AND end_date >= ?", date, date) }
    scope :active, -> { active_at(Date.current) }
    scope :expired, -> { where("end_date < ?", Date.current) }
    scope :upcoming, -> { where("start_date > ?", Date.current) }

    validates :start_date, :end_date, presence: true
    validate :end_date_after_start_date
  end

  def active?(date = Date.current)
    return false unless start_date && end_date
    date.between?(start_date, end_date)
  end

  private

  def end_date_after_start_date
    if start_date && end_date && end_date < start_date
      errors.add(:end_date, "must be after or equal to start date")
    end
  end
end
