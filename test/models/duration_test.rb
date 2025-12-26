require "test_helper"

class DurationTest < ActiveSupport::TestCase
  setup do
    @course = products(:yoga_monthly)       # Istituzionale (30gg)
    @membership = products(:annual_membership) # Associativo (365gg)
  end

  test "institutional starts on preference date (NO MORE beginning of month)" do
    # Scenario: Pago il 20 Gennaio
    preference_date = Date.new(2025, 1, 20)

    # Calcolo
    result = Duration.new(@course, preference_date).calculate

    # Verifica: DEVE iniziare il 20, non il 1°
    assert_equal Date.new(2025, 1, 20), result[:start_date]

    # Verifica: Finisce tra un mese esatto (-1 giorno)
    # Dal 20 Gen al 19 Feb (30 giorni inclusivi se usiamo logica mensile)
    expected_end = Date.new(2025, 1, 20).advance(months: 1).yesterday
    assert_equal expected_end, result[:end_date]
  end

  test "institutional caps at Sport Year End" do
    # Scenario: Corso mensile comprato il 15 Agosto 2025
    # L'anno sportivo finisce il 31 Agosto
    preference_date = Date.new(2025, 8, 15)

    result = Duration.new(@course, preference_date).calculate

    assert_equal Date.new(2025, 8, 15), result[:start_date]
    # DEVE fermarsi al 31 Agosto, anche se il mese finirebbe il 14 Settembre
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end

  test "associative covers full sport year" do
    # Scenario: Iscrizione il 15 Maggio 2025
    preference_date = Date.new(2025, 5, 15)

    result = Duration.new(@membership, preference_date).calculate

    assert_equal preference_date, result[:start_date]
    # Scadenza fissa fine anno sportivo (31/08) o 365gg?
    # Dipende dalla tua logica in Duration.rb per gli associativi.
    # Se usi SportYear.end_date_for:
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end
end
