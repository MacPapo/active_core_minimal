require "test_helper"

class SubscriptionTest < ActiveSupport::TestCase
  setup do
    Subscription.delete_all
    Sale.delete_all

    @member = members(:bob)
    @staff = users(:staff)

    grant_membership_to(@member)

    @prod_inst = products(:yoga_monthly)
    @prod_inst.update!(duration_days: 30, accounting_category: "institutional")
  end

  test "automatically calculates dates based on sale date (Standard Flow)" do
    # Scenario: Vendita fatta il 20 Gennaio
    sale_date = Date.new(2025, 1, 20)

    sale = Sale.create!(
      member: @member,
      user: users(:staff),
      product: @prod_inst,
      sold_on: sale_date,
      subscription_attributes: { member: @member, product: @prod_inst }
    )

    # Recuperiamo la subscription generata automaticamente
    sub = sale.subscription

    # Verifica Inizio: DEVE essere la data di vendita (20 Gen)
    assert_equal Date.new(2025, 1, 20), sub.start_date

    # Verifica Fine: 1 mese dopo (-1 giorno)
    expected_end = Date.new(2025, 1, 20).advance(months: 1).yesterday
    assert_equal expected_end, sub.end_date
  end

  test "respects user preference for future start date" do
    # Oggi è 20 Gennaio, ma l'utente vuole iniziare il 1° Febbraio
    sale_date = Date.new(2025, 1, 20)
    future_start = Date.new(2025, 2, 1)

    sale = Sale.create!(
      member: @member, product: @prod_inst, user: @staff,
      sold_on: sale_date, payment_method: :cash
    )

    # Passiamo start_date esplicita -> Duration la userà come preference_date
    sub = Subscription.create!(
      member: @member, product: @prod_inst, sale: sale,
      start_date: future_start
    )

    assert_equal Date.new(2025, 2, 1), sub.start_date
    assert_equal Date.new(2025, 2, 28), sub.end_date

    # Oggi non attivo, futuro sì
    assert_not sub.active?(sale_date)
    assert sub.active?(future_start)
  end

  test "scopes filter correctly" do
    today = Date.current
    sale = Sale.create!(member: @member, product: @prod_inst, user: @staff, sold_on: today)

    # 1. Scaduto
    expired = Subscription.create!(
      member: @member, product: @prod_inst, sale: sale,
      start_date: today - 2.months, end_date: today - 1.month
    )

    # 2. Attivo
    active = Subscription.create!(
      member: @member, product: @prod_inst, sale: sale,
      start_date: today.beginning_of_month, end_date: today.end_of_month
    )

    # 3. Futuro
    upcoming = Subscription.create!(
      member: @member, product: @prod_inst, sale: sale,
      start_date: today + 1.month, end_date: today + 2.months
    )

    assert_includes Subscription.active, active
    assert_not_includes Subscription.active, expired
    assert_not_includes Subscription.active, upcoming

    assert_includes Subscription.expired, expired
    assert_includes Subscription.upcoming, upcoming
  end

  test "validates end date after start date" do
    sale = Sale.create!(member: @member, product: @prod_inst, user: @staff, sold_on: Date.today)

    sub = Subscription.new(
      member: @member, product: @prod_inst, sale: sale,
      start_date: Date.today,
      end_date: Date.yesterday # Errore manuale
    )

    assert_not sub.valid?
    assert_includes sub.errors[:end_date], "must be after or equal to start date"
  end
end
