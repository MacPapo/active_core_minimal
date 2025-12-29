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
      return unless subscription # Evita crash se sub non c'è

      # Usiamo la start_date effettiva della subscription
      check_date = subscription.start_date

      unless member.membership_valid?(check_date)
        errors.add(:base, "Impossibile vendere #{product.name}: Il socio non avrà una Quota Associativa attiva il #{I18n.l(check_date)}.")
      end
    end

    def apply_smart_renewal_policy
      return unless subscription.present?

      subscription.member = member
      subscription.product = product

      # CASO 1: L'operatore ha forzato una data di inizio (MANUAL OVERRIDE)
      if subscription.start_date.present?
        # Se manca la fine, la calcoliamo basandoci sulla data manuale
        if subscription.end_date.blank?
          duration_result = Duration.new(product, subscription.start_date).calculate
          subscription.end_date = duration_result[:end_date]
        end
        # STOP! Non chiamare RenewalCalculator, l'umano ha deciso.
        return
      end

      # CASO 2: Nessuna data inserita -> AUTOMATISMO (Smart Renewal)
      ref_date = sold_on || Date.current

      # Qui chiamiamo il "Genio" che decide start e end
      result = RenewalCalculator.new(member, product, ref_date).call

      subscription.start_date = result[:start_date]
      subscription.end_date   = result[:end_date]
    end
end
