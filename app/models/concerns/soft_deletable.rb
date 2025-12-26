module SoftDeletable
  extend ActiveSupport::Concern

  included do
    # Definiamo lo scope per vedere solo le cose "vive"
    scope :kept, -> { where(discarded_at: nil) }

    # Definiamo lo scope per vedere le cose "cestinate"
    scope :discarded, -> { where.not(discarded_at: nil) }
  end

  # Controlla se è stato cancellato
  def discarded?
    discarded_at.present?
  end

  # L'azione di cancellazione (soft)
  def discard!
    touch(:discarded_at)
  end

  # L'azione di ripristino
  def undiscard!
    update!(discarded_at: nil)
  end
end
