require "test_helper"

class SubscriptionIssuerTest < ActiveSupport::TestCase
  setup do
    @member = members(:alice)
    @user = users(:staff)
    @product = products(:yoga_monthly)

    grant_membership_to(@member)
  end

  test "creates sale and subscription together (Nested Attributes)" do
    # Simuliamo i parametri che arriverebbero dal form
    sale_params = {
      member: @member,
      user: @user,
      product: @product,
      sold_on: Date.today,
      payment_method: :cash,
      subscription_attributes: {
        member: @member,
        product: @product,
        start_date: Date.today,
        end_date: Date.today + 1.year
      }
    }

    assert_difference [ "Sale.count", "Subscription.count" ], 1 do
      sale = Sale.create!(sale_params)

      # Verifica che siano collegati
      assert sale.subscription.present?
      assert_equal sale, sale.subscription.sale
    end
  end

  test "discarding sale cascades to subscription" do
    # Setup: Creiamo una vendita con abbonamento
    sale = Sale.create!(
      member: @member,
      user: @user,
      product: @product,
      sold_on: Date.today,
      subscription_attributes: { member: @member, product: @product, start_date: Date.today, end_date: Date.today + 30.days }
    )

    subscription = sale.subscription

    # Stato iniziale: Entrambi vivi
    assert_not sale.discarded?
    assert_not subscription.discarded?

    # AZIONE: Cancelliamo la vendita
    sale.discard!

    # VERIFICA: L'abbonamento deve essere morto
    assert sale.reload.discarded?
    assert subscription.reload.discarded?, "L'abbonamento dovrebbe essere stato cestinato insieme alla vendita"
  end

  test "undiscarding sale cascades to subscription" do
    # Setup: Partiamo da entrambi cestinati
    sale = Sale.create!(
      member: @member,
      user: @user,
      product: @product,
      sold_on: Date.today,
      subscription_attributes: { member: @member, product: @product, start_date: Date.today, end_date: Date.today + 30.days }
    )
    sale.discard!

    assert sale.discarded?
    assert sale.subscription.discarded?

    # AZIONE: Ripristino
    sale.undiscard!

    # VERIFICA: Entrambi vivi
    assert_not sale.reload.discarded?
    assert_not sale.subscription.reload.discarded?
  end

  test "discarding sale without subscription implies no error" do
    simple_product = products(:yoga_monthly)

    sale = Sale.create!(
      member: @member,
      user: @user,
      product: simple_product,
      sold_on: Date.today
    )

    assert_nil sale.subscription

    # AZIONE: Discard
    assert_nothing_raised do
      sale.discard!
    end

    assert sale.discarded?
  end

  test "smart renewal: continuity for anticipated renewal" do
    # Scenario: Alice ha un abbonamento che scade tra 5 giorni
    expiry_date = Date.today + 5.days
    create_past_subscription(end_date: expiry_date)

    # Azione: Compra un rinnovo OGGI
    sale = create_sale_with_smart_subscription

    # Verifica: Il nuovo deve partire tra 6 giorni (expiry + 1)
    assert_equal (expiry_date + 1.day), sale.subscription.start_date
  end

  test "smart renewal: continuity (punishment) for small gap" do
    # Scenario: Alice è scaduta da 10 giorni (dentro i 30 di tolleranza)
    # Esempio: Oggi 26 Dic, Scaduta il 16 Dic.
    expiry_date = Date.today - 10.days
    create_past_subscription(end_date: expiry_date)

    # Azione: Compra un rinnovo OGGI
    sale = create_sale_with_smart_subscription

    # Verifica: Il nuovo deve partire nel passato (expiry + 1) per coprire il buco
    expected_start = expiry_date + 1.day # 17 Dic
    assert_equal expected_start, sale.subscription.start_date

    # Verifica collaterale: L'abbonamento nuovo è già consumato per 10 giorni
    assert sale.subscription.start_date < Date.today
  end

  test "smart renewal: reset to today for huge gap" do
    # Scenario: Alice è scaduta da 60 giorni (fuori tolleranza)
    expiry_date = Date.today - 60.days
    create_past_subscription(end_date: expiry_date)

    # Azione: Compra un rinnovo OGGI
    sale = create_sale_with_smart_subscription

    # Verifica: Il nuovo deve partire OGGI (niente retroattività assurda)
    assert_equal Date.today, sale.subscription.start_date
  end

  test "smart renewal: manual date overrides logic" do
    expiry_date = Date.today - 10.days # Sarebbe caso "Piccolo Buco"
    create_past_subscription(end_date: expiry_date)

    # Azione: L'operatore forza una data futura (es. 1° Gennaio)
    manual_date = Date.today + 1.month

    sale_params = default_sale_params
    sale_params[:subscription_attributes][:start_date] = manual_date # OVERRIDE

    sale = Sale.create!(sale_params)

    # Verifica: Vince l'umano
    assert_equal manual_date, sale.subscription.start_date
  end

  private

  def default_sale_params
    {
      member: @member,
      user: @user,
      product: @product, # Assumiamo durata 365gg o simile
      sold_on: Date.today,
      payment_method: :cash,
      subscription_attributes: {
        member: @member,
        product: @product
        # NOTA: start_date e end_date assenti per far scattare l'automatismo
      }
    }
  end

  def create_sale_with_smart_subscription
    Sale.create!(default_sale_params)
  end

  def create_past_subscription(end_date:)
    # Creiamo una subscription "vecchia" scollegata da vendita per semplicità
    # (o collegata a vendita fittizia)
    # Calcoliamo start in base a end (es. 30gg prima)
    start_date = end_date - 30.days

    Subscription.create!(
      member: @member,
      product: @product,
      start_date: start_date,
      end_date: end_date,
      sale: Sale.create!(member: @member, user: @user, product: @product, sold_on: start_date)
    )
  end
end
