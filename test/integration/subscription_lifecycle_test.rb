require "test_helper"

class SubscriptionLifecycleTest < ActiveSupport::TestCase
  setup do
    @member = members(:alice)
    @user = users(:staff)
    
    @monthly_course = products(:yoga_monthly)
    @membership_annual = products(:annual_membership)

    grant_membership_to(@member)
  end

  test "Full Chain: Sale -> Issuer -> Subscription -> Duration -> SportYear" do
    # 1. SETUP: Simuliamo un rinnovo intelligente
    # Alice aveva un abbonamento scaduto ieri.
    yesterday = Date.yesterday

    # Creiamo il passato manualmente
    Subscription.create!(
      member: @member,
      product: @monthly_course,
      sale: Sale.create!(member: @member, user: @user, product: @monthly_course, sold_on: yesterday - 30.days),
      start_date: yesterday - 30.days,
      end_date: yesterday
    )

    # 2. AZIONE: Vendita oggi (sold_on: Today)
    sale = Sale.create!(
      member: @member,
      user: @user,
      product: @monthly_course,
      sold_on: Date.today,
      payment_method: :cash,
      subscription_attributes: { member: @member, product: @monthly_course }
    )

    # 3. VERIFICHE A CASCATA

    # A. SubscriptionIssuer ha lavorato?
    # La data inizio deve essere OGGI (Today), perché ieri scadeva. Continuità perfetta.
    expected_start = Date.today
    assert_equal expected_start, sale.subscription.start_date, "Smart Renewal failed: Start date should be today"

    # B. Duration ha lavorato?
    # La data fine deve essere tra 1 mese (-1 giorno) perché è un mensile
    # Nota: duration_days è 30, quindi la logica institutional usa advance(months: 1).yesterday
    expected_end = expected_start.advance(months: 1).yesterday
    assert_equal expected_end, sale.subscription.end_date, "Duration calculation failed: End date incorrect"
  end

  test "The August 31st Wall (SportYear interaction)" do
    # Simuliamo una vendita fatta il 15 Agosto per un mensile
    # Deve finire il 31 Agosto, non il 14 Settembre.

    # Usiamo un anno sicuro (es. 2025)
    august_15 = Date.new(2025, 8, 15)

    sale = Sale.create!(
      member: @member,
      user: @user,
      product: @monthly_course,
      sold_on: august_15,
      subscription_attributes: { member: @member, product: @monthly_course }
    )

    # Verifica Inizio
    assert_equal august_15, sale.subscription.start_date

    # Verifica Fine (Muro SportYear)
    limit_date = Date.new(2025, 8, 31)

    assert_equal limit_date, sale.subscription.end_date, "SportYear wall failed: Should end on Aug 31st"
  end

  test "Membership Guard: Cannot buy course without active membership" do
    # 1. Creiamo un utente nuovo "pulito" (senza abbonamenti)
    new_guy = Member.create!(
      first_name: "New", last_name: "Guy",
      fiscal_code: "NWGGUY90A01H501X", birth_date: "1990-01-01"
    )

    # 2. Proviamo a vendergli YOGA (Corso Istituzionale)
    # Dovrebbe FALLIRE
    sale = Sale.new(
      member: new_guy,
      user: @user,
      product: @monthly_course, # Yoga
      sold_on: Date.today,
      subscription_attributes: { member: new_guy, product: @monthly_course }
    )

    assert_not sale.save, "Should NOT save sale without membership"
    assert_includes sale.errors[:base].join, "Quota Associativa"

    # 3. Ora gli vendiamo la QUOTA ASSOCIATIVA
    # Dovrebbe PASSARE
    membership_sale = Sale.create!(
      member: new_guy,
      user: @user,
      product: @membership_annual, # Quota 2025
      sold_on: Date.today,
      subscription_attributes: { member: new_guy, product: @membership_annual }
    )
    assert membership_sale.persisted?

    # 4. Riprovasmo a vendergli YOGA
    # Ora dovrebbe PASSARE perché è coperto
    sale_retry = Sale.new(
      member: new_guy,
      user: @user,
      product: @monthly_course,
      sold_on: Date.today,
      subscription_attributes: { member: new_guy, product: @monthly_course }
    )

    assert sale_retry.save!, "Should SAVE sale now that membership exists"
  end
end
