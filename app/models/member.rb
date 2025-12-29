class Member < ApplicationRecord
  include SoftDeletable, Personable, HasAddress, Avatarable

  normalizes :fiscal_code, with: ->(c) { c.strip.upcase }

  validates :birth_date, presence: true
  validates :fiscal_code,
            presence: true,
            uniqueness: { conditions: -> { kept } },
            format: { with: /\A[A-Z0-9]{16}\z/, message: "must be 16 alphanumeric characters" }

  validates :phone, phone: { possible: true, allow_blank: true, types: [ :mobile, :fixed_line ] }

  has_many :sales, dependent: :restrict_with_error
  has_many :access_logs, dependent: :destroy
  has_many :subscriptions, dependent: :destroy
  has_many :memberships, -> { joins(:product).merge(Product.associative) },
           class_name: "Subscription"

  def medical_certificate_valid?(date = Date.today)
    return false if medical_certificate_expiry.nil?

    medical_certificate_expiry >= date
  end

  def membership_expiry_date
    memberships.kept.maximum(:end_date)
  end

  def membership_valid?(date = Date.today)
    expiry = membership_expiry_date
    return false if expiry.nil?

    expiry >= date
  end

  def compliant?(date = Date.today)
    medical_certificate_valid?(date) && membership_valid?(date)
  end

  def status_label
    return "error" if discarded?
    return "warning" unless compliant?
    "success"
  end

  def relevant_subscriptions
    source = subscriptions.loaded? ? subscriptions : subscriptions.includes(:product)
    active_source = source.select { |sub| sub.kept? }

    sorted = active_source.sort_by(&:end_date).reverse

    latest_per_product = sorted.uniq(&:product_id)

    cutoff_date = 60.days.ago.to_date
    visible = latest_per_product.select do |sub|
      sub.end_date >= cutoff_date
    end

    visible.sort_by { |sub| (sub.end_date - Date.current).to_i }
  end

  def renewal_info_for(product)
    return nil unless product

    # 1. Troviamo le discipline del nuovo prodotto
    # (Assumiamo che tu abbia sistemato has_many :disciplines nel model Product come ci siamo detti prima)
    discipline_ids = product.discipline_ids

    # 2. Cerchiamo l'ultimo abbonamento di questo socio che ha ALMENO una di quelle discipline
    #    E che non sia stato cancellato (kept)
    last_sub = subscriptions.kept
                 .joins(product: :product_disciplines)
                 .where(product_disciplines: { discipline_id: discipline_ids })
                 .order(end_date: :desc)
                 .first

    # 3. Logica Continuità
    suggested_start = Date.current

    if last_sub
      # Se scade nel futuro O è scaduto da meno di 30 giorni (tolleranza)
      # diamo continuità.
      if last_sub.end_date >= 30.days.ago.to_date
        suggested_start = last_sub.end_date + 1.day
      end
    end

    # 4. Calcoliamo la fine in base alla durata del nuovo prodotto
    # (product.duration_days deve essere un intero nel DB)
    suggested_end = suggested_start + product.duration_days.days - 1.day

    # Ritorniamo un hash semplice
    {
      start_date: suggested_start,
      end_date: suggested_end,
      last_subscription_end: last_sub&.end_date # Utile per debugging o messaggi UI
    }
  end
end
