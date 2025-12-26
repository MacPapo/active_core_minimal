require "test_helper"

class SaleTest < ActiveSupport::TestCase
  setup do
    Sale.delete_all

    @member = members(:bob)
    @user = users(:staff)
    @prod_inst = products(:yoga_monthly)
    @prod_inst.update_columns(
      name: "Yoga Course",
      price_cents: 5000,
      accounting_category: "institutional"
    )

    @prod_assoc = products(:annual_membership)
    @prod_assoc.update_columns(
      name: "Tessera 2025",
      price_cents: 2000,
      accounting_category: "associative"
    )

    grant_membership_to(@member)
  end

  test "cash payment generates receipt number and year" do
    sale = Sale.create!(
      member: @member, product: @prod_inst, user: @user,
      sold_on: Date.today, payment_method: :cash
    )

    assert sale.cash?
    assert_not_nil sale.receipt_number
    assert_equal 1, sale.receipt_number
    assert_not_nil sale.receipt_year
    assert_equal "institutional", sale.receipt_sequence
  end

  test "credit card payment DOES NOT generate receipt number" do
    sale = Sale.create!(
      member: @member, product: @prod_inst, user: @user,
      sold_on: Date.today, payment_method: :credit_card
    )

    assert sale.credit_card?
    assert_nil sale.receipt_number
    assert_nil sale.receipt_year
    assert_equal "institutional", sale.receipt_sequence
  end

  test "bank transfer payment DOES NOT generate receipt number" do
    sale = Sale.create!(
      member: @member, product: @prod_inst, user: @user,
      sold_on: Date.today, payment_method: :bank_transfer
    )
    assert_nil sale.receipt_number
  end

  test "counting skips non-cash payments correctly" do
    current_year = Date.today.year

    # 1. Vendita CASH -> Ricevuta n. 1
    s1 = Sale.create!(member: @member, product: @prod_inst, user: @user, payment_method: :cash, sold_on: Date.today)
    assert_equal 1, s1.receipt_number

    # 2. Vendita CARTA -> Niente numero (Non deve consumare il n. 2)
    s2 = Sale.create!(member: @member, product: @prod_inst, user: @user, payment_method: :credit_card, sold_on: Date.today)
    assert_nil s2.receipt_number

    # 3. Vendita CASH -> Ricevuta n. 2 (Non n. 3!)
    s3 = Sale.create!(member: @member, product: @prod_inst, user: @user, payment_method: :cash, sold_on: Date.today)
    assert_equal 2, s3.receipt_number

    # Verifica codici virtuali
    # Nota: Reload necessario per leggere colonne generate dal DB
    assert_equal "#{current_year}-institutional-1", s1.reload.receipt_code
    assert_nil s2.reload.receipt_code
    assert_equal "#{current_year}-institutional-2", s3.reload.receipt_code
  end

  test "sequences are independent even with mixed payments" do
    # Cash Istituzionale -> n.1
    s1 = Sale.create!(member: @member, product: @prod_inst, user: @user, payment_method: :cash, sold_on: Date.today)
    assert_equal 1, s1.receipt_number
    assert_equal "institutional", s1.receipt_sequence

    # Cash Associativo -> n.1 (Nuova serie indipendente)
    s2 = Sale.create!(member: @member, product: @prod_assoc, user: @user, payment_method: :cash, sold_on: Date.today)
    assert_equal 2, s2.receipt_number
    assert_equal "associative", s2.receipt_sequence

    # Carta Istituzionale -> NULL
    s3 = Sale.create!(member: @member, product: @prod_inst, user: @user, payment_method: :credit_card, sold_on: Date.today)
    assert_nil s3.receipt_number

    # Cash Istituzionale -> n.2 (Riprende la serie istituzionale)
    s4 = Sale.create!(member: @member, product: @prod_inst, user: @user, payment_method: :cash, sold_on: Date.today)
    assert_equal 2, s4.receipt_number
  end

  test "virtual column receipt_code works in DB" do
    sale = Sale.create!(
      member: @member, product: @prod_inst, user: @user,
      payment_method: :cash, sold_on: Date.today
    )
    sale.reload
    expected_code = "#{Date.today.year}-institutional-1"
    assert_equal expected_code, sale.receipt_code
  end

  test "snapshots product details on creation" do
    # Creiamo la vendita SENZA specificare amount, deve prenderlo dal prodotto
    sale = Sale.create!(
      member: @member,
      product: @prod_inst, # Ha price_cents: 5000 (settato nel setup)
      user: @user,
      sold_on: Date.today,
      payment_method: :cash
    )

    # Verifica Snapshot Nome
    assert_equal "Yoga Course", sale.product_name_snapshot

    # Verifica Snapshot Prezzo
    assert_equal 5000, sale.amount_cents
    assert_equal "institutional", sale.receipt_sequence

    # CAMBIAMENTO PRODOTTO FUTURO
    @prod_inst.update!(name: "Yoga New Price", price_cents: 9999)

    # La vendita vecchia deve rimanere immutata (Congelata)
    sale.reload
    assert_equal "Yoga Course", sale.product_name_snapshot
    assert_equal 5000, sale.amount_cents
  end

  test "resets numbering on new year" do
    # Vendita nel 2024
    Sale.create!(
      member: @member, product: @prod_inst, user: @user,
      sold_on: Date.new(2024, 12, 31), payment_method: :cash
    )

    # Vendita nel 2025 -> Deve ripartire da 1
    sale_2025 = Sale.create!(
      member: @member, product: @prod_inst, user: @user,
      sold_on: Date.new(2025, 1, 1), payment_method: :cash
    )

    assert_equal 2025, sale_2025.receipt_year
    assert_equal 1, sale_2025.receipt_number
  end

  test "monetizable handles strings with italian formatting" do
    sale = Sale.new

    # Caso difficile: 1.200,50 (Mille e duecento virgola cinquanta)
    sale.amount = "1.200,50"
    assert_equal 120050, sale.amount_cents
    assert_equal 1200.5, sale.amount

    # Caso standard: 50
    sale.amount = "50"
    assert_equal 5000, sale.amount_cents

    # Caso virgola semplice: 12,50
    sale.amount = "12,50"
    assert_equal 1250, sale.amount_cents
  end
end
