module Trackable
  extend ActiveSupport::Concern

  included do
    has_many :activity_logs, as: :subject, dependent: :destroy
  end

  def log_activity(user, action, details = {})
    activity_logs.create!(
      user: user,
      action: action,
      details: details
    )
  end
end
