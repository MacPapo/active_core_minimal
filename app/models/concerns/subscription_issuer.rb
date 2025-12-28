module SubscriptionIssuer
  extend ActiveSupport::Concern

  RENEWAL_GRACE_PERIOD_DAYS = 30

  included do
    has_one :subscription, dependent: :destroy, inverse_of: :sale
    accepts_nested_attributes_for :subscription, allow_destroy: true

    after_discard :discard_subscription
    after_undiscard :undiscard_subscription

    before_validation :apply_smart_renewal_policy, on: :create

    validate :require_active_membership_for_courses, on: :create
  end

  private
    def discard_subscription
      subscription&.discard!
    end

    def undiscard_subscription
      subscription&.undiscard!
    end

    def require_active_membership_for_courses
      return if product.nil? || product.associative?

      check_date = subscription&.start_date || sold_on || Date.current
      unless member.membership_valid?(check_date)
        errors.add(:base, "Impossibile vendere un corso istituzionale: Il socio non ha una Quota Associativa attiva per la data #{check_date.strftime('%d/%m/%Y')}.")
      end
    end

    def apply_smart_renewal_policy
      return unless subscription.present?

      subscription.member  = member
      subscription.product = product

      return if subscription.start_date.present?

      last_sub = Subscription.kept
                             .where(member: member, product: product)
                             .where.not(id: subscription.id)
                             .order(end_date: :desc)
                             .first

      target_start_date = sold_on || Date.current

      if last_sub
        continuity_date = last_sub.end_date + 1.day
        gap_days = ((sold_on || Date.current) - continuity_date).to_i

        if gap_days < 0
          # CASO 1: Rinnovo Anticipato (Gap negativo, sono venuto prima della scadenza)
          # Esempio: Scade il 31, vengo il 20. Gap = -11.
          # Azione: Mantengo la continuità futura.
          target_start_date = continuity_date

        elsif gap_days <= RENEWAL_GRACE_PERIOD_DAYS
          # CASO 2: Piccolo Buco (Punizione/Recupero)
          # Esempio: Scaduto da 10 giorni. Gap = 10.
          # Azione: Mantengo la continuità passata (pago il buco).
          target_start_date = continuity_date
        else
          # CASO 3: Buco Enorme (Reset)
          # Esempio: Scaduto da 6 mesi.
          # Azione: Ignoro il passato, uso la data odierna (già impostata sopra come default).
        end
      end

      subscription.start_date = target_start_date
    end
end
