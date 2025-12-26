module SoftDeletable
  extend ActiveSupport::Concern

  included do
    define_model_callbacks :discard, :undiscard

    scope :kept, -> { where(discarded_at: nil) }
    scope :discarded, -> { where.not(discarded_at: nil) }
  end

  def discarded?
    discarded_at.present?
  end

  def discard!
    run_callbacks(:discard) do
      touch(:discarded_at)
    end
  end

  def undiscard!
    run_callbacks(:undiscard) do
      update!(discarded_at: nil)
    end
  end
end
