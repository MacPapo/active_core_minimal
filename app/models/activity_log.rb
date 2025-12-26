class ActivityLog < ApplicationRecord
  belongs_to :user
  belongs_to :subject, polymorphic: true

  validates :user, :subject, :action, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_subject, ->(subject) { where(subject: subject) }
end
