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
      # 1. Se il prodotto è NULL o è esso stesso una Quota Associativa, usciamo.
      # (Non serve la tessera per comprare la tessera)
      return if product.nil? || product.associative?

      # 2. Determiniamo la data in cui il corso dovrebbe iniziare
      # Nota: Usiamo subscription.start_date se calcolata, altrimenti sold_on
      check_date = subscription&.start_date || sold_on || Date.current

      # 3. Chiediamo al Member se in quella data sarà coperto
      # Nota: member.membership_valid? l'hai già nel modello Member, usiamolo!
      unless member.membership_valid?(check_date)
        errors.add(:base, "Impossibile vendere un corso istituzionale: Il socio non ha una Quota Associativa attiva per la data #{check_date.strftime('%d/%m/%Y')}.")
      end
    end

    def apply_smart_renewal_policy
      # 1. Se non c'è abbonamento o se l'utente ha già messo una data manuale, fermati.
      return unless subscription.present?
      return if subscription.start_date.present?

      # 2. Cerchiamo l'ultima sottoscrizione per QUESTO membro e QUESTO prodotto
      # Nota: Escludiamo noi stessi (in caso di salvataggi strani)
      last_sub = Subscription.kept
                             .where(member: member, product: product)
                             .where.not(id: subscription.id)
                             .order(end_date: :desc)
                             .first

      # Default: Se non c'è storia, si parte da oggi (o dalla data vendita)
      target_start_date = sold_on || Date.current

      if last_sub
        continuity_date = last_sub.end_date + 1.day

        # Calcoliamo la distanza tra OGGI e la data di continuità ideale
        # Esempio: continuità = 1 Nov, sold_on = 20 Nov -> gap = 19 giorni
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

      # 3. Applichiamo la data calcolata
      subscription.start_date = target_start_date

      # Nota: Non serve calcolare end_date qui.
      # Ci penserà il modello Subscription nel suo before_validation usando la duration del prodotto.
    end
end
