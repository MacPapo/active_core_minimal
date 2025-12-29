require "test_helper"

class SubscriptionIssuerTest < ActiveSupport::TestCase
  setup do
    @member = members(:alice)
    @user = users(:staff)
    @product = products(:yoga_monthly) # Ipotizziamo duri 1 mese / 30gg

    grant_membership_to(@member)
  end

  # --- TEST BASE ---

  test "creates sale and subscription together (Nested Attributes)" do
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
        end_date: Date.today + 1.year # Qui forziamo noi le date
      }
    }

    assert_difference [ "Sale.count", "Subscription.count" ], 1 do
      sale = Sale.create!(sale_params)
      assert sale.subscription.present?
      assert_equal sale, sale.subscription.sale
    end
  end

  # --- TEST SOFT DELETE (Ciclo di vita & Sicurezza Loop) ---

  test "discarding sale cascades to subscription" do
    sale = create_sale_with_smart_subscription
    subscription = sale.subscription

    assert_not sale.discarded?
    assert_not subscription.discarded?

    # AZIONE: Cancello PADRE -> Cancella FIGLIO
    sale.discard!

    assert sale.reload.discarded?
    assert subscription.reload.discarded?, "La vendita doveva tirarsi dietro l'abbonamento"
  end

  test "discarding subscription cascades to sale (Reverse Safety Check)" do
    sale = create_sale_with_smart_subscription
    subscription = sale.subscription

    # AZIONE: Cancello FIGLIO -> Cancella PADRE
    # Questo è il test critico per il "Loop Infinito". Se il codice è sbagliato, questo test va in timeout/stack overflow.
    subscription.discard!

    assert subscription.reload.discarded?
    assert sale.reload.discarded?, "L'abbonamento doveva tirarsi dietro la vendita"
  end

  test "undiscarding sale cascades to subscription" do
    sale = create_sale_with_smart_subscription
    sale.discard!

    # AZIONE: Ripristino
    sale.undiscard!

    assert_not sale.reload.discarded?
    assert_not sale.subscription.reload.discarded?
  end

  # --- TEST VALIDAZIONI BUSINESS ---

  test "cannot sell course without active membership" do
    # Scenario: Alice non ha la tessera (o è scaduta)
    @member.memberships.destroy_all

    sale_params = default_sale_params
    sale = Sale.new(sale_params)

    # Verifica: Il salvataggio deve fallire
    assert_not sale.save, "Non dovrebbe permettere la vendita senza tessera"
    assert_includes sale.errors[:base].join, "non avrà una Quota Associativa attiva"
  end

  # --- TEST SMART RENEWAL & DURATION ---

  test "smart renewal: continuity for anticipated renewal" do
    # Scenario: Scade tra 5 giorni
    expiry_date = Date.today + 5.days
    create_past_subscription(end_date: expiry_date)

    sale = create_sale_with_smart_subscription

    # 1. Start Date: Continuità (Expiry + 1)
    expected_start = expiry_date + 1.day
    assert_equal expected_start, sale.subscription.start_date

    # 2. End Date: Deve esistere ed essere calcolata (Start + 1 Mese circa)
    assert sale.subscription.end_date.present?, "End date mancante!"
    assert sale.subscription.end_date > expected_start
  end

  test "smart renewal: continuity (punishment) for small gap" do
    # Scenario: Scaduta da 10 giorni
    expiry_date = Date.today - 10.days
    create_past_subscription(end_date: expiry_date)

    sale = create_sale_with_smart_subscription

    # 1. Start Date: Backdate per coprire il buco
    expected_start = expiry_date + 1.day
    assert_equal expected_start, sale.subscription.start_date
    assert sale.subscription.start_date < Date.today

    # 2. End Date: Deve essere calcolata correttamente rispetto allo start retroattivo
    assert sale.subscription.end_date.present?
  end

  test "smart renewal: reset to today for huge gap" do
    # Scenario: Scaduta da 60 giorni
    expiry_date = Date.today - 60.days
    create_past_subscription(end_date: expiry_date)

    sale = create_sale_with_smart_subscription

    # 1. Start Date: Reset a oggi
    assert_equal Date.today, sale.subscription.start_date

    # 2. End Date: Deve partire da oggi
    assert sale.subscription.end_date.present?
    assert sale.subscription.end_date > Date.today
  end

  test "smart renewal: manual date overrides logic" do
    expiry_date = Date.today - 10.days
    create_past_subscription(end_date: expiry_date)

    manual_date = Date.today + 1.month

    sale_params = default_sale_params
    sale_params[:subscription_attributes][:start_date] = manual_date # OVERRIDE

    sale = Sale.create!(sale_params)

    # 1. Start Date: Vince l'umano
    assert_equal manual_date, sale.subscription.start_date

    # 2. End Date: Il sistema deve comunque calcolare la fine basandosi sulla data manuale
    assert sale.subscription.end_date.present?
    # Se il corso dura 1 mese, deve finire 1 mese dopo la data manuale
    assert sale.subscription.end_date > manual_date
  end

  private

  def default_sale_params
    {
      member: @member,
      user: @user,
      product: @product,
      sold_on: Date.today,
      payment_method: :cash,
      subscription_attributes: {
        member: @member,
        product: @product
        # Niente date: lasciamo fare al sistema
      }
    }
  end

  def create_sale_with_smart_subscription
    Sale.create!(default_sale_params)
  end

  def create_past_subscription(end_date:)
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
