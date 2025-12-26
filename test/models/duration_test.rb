require "test_helper"

class DurationTest < ActiveSupport::TestCase
  setup do
    @prod_mensile = products(:yoga_monthly)
    @prod_mensile.update!(duration_days: 30, accounting_category: "institutional")

    @prod_trimestrale = products(:yoga_monthly).dup
    @prod_trimestrale.duration_days = 90

    @prod_tessera = products(:annual_membership)
    @prod_tessera.update!(duration_days: 365, accounting_category: "associative")
  end

  test "institutional aligns to 1st of month (Current Month Payment)" do
    # Pago il 20 Gennaio
    date = Date.new(2025, 1, 20)
    result = Duration.new(@prod_mensile, date).calculate

    assert_equal Date.new(2025, 1, 1), result[:start_date]
    assert_equal Date.new(2025, 1, 31), result[:end_date]
  end

  test "institutional aligns to 1st of month (Future Month Selection)" do
    # Scelgo di iniziare a Febbraio
    date = Date.new(2025, 2, 1)
    result = Duration.new(@prod_mensile, date).calculate

    assert_equal Date.new(2025, 2, 1), result[:start_date]
    assert_equal Date.new(2025, 2, 28), result[:end_date]
  end

  test "institutional caps at Sport Year End" do
    # Compro un trimestrale (Lug-Ago-Set) il 15 Luglio
    date = Date.new(2025, 7, 15)
    result = Duration.new(@prod_trimestrale, date).calculate

    assert_equal Date.new(2025, 7, 1), result[:start_date]
    # Invece di finire il 30 Settembre, deve fermarsi al 31 Agosto
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end

  test "associative starts on day of payment" do
    # Pago il 15 Gennaio
    date = Date.new(2025, 1, 15)
    result = Duration.new(@prod_tessera, date).calculate

    assert_equal date, result[:start_date]
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end
end
