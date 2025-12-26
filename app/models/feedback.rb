class Feedback < ApplicationRecord
  belongs_to :user

  enum :status, {
    pending: 0,
    in_progress: 1,
    resolved: 2,
    rejected: 3
  }, default: :pending

  validates :message, presence: true
  validates :user, presence: true
end
