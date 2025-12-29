require "test_helper"

class DurationTest < ActiveSupport::TestCase
  setup do
    @course = products(:yoga_monthly)        # Istituzionale (30gg)
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
    # Dal 20 Gen al 19 Feb
    expected_end = Date.new(2025, 1, 20).advance(months: 1).yesterday
    assert_equal expected_end, result[:end_date]
  end

  test "institutional caps at Sport Year End" do
    # Scenario: Corso mensile comprato il 15 Agosto 2025
    preference_date = Date.new(2025, 8, 15)

    result = Duration.new(@course, preference_date).calculate

    assert_equal Date.new(2025, 8, 15), result[:start_date]
    # DEVE fermarsi al 31 Agosto
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end

  test "associative covers full sport year" do
    # Scenario: Iscrizione il 15 Maggio 2025
    preference_date = Date.new(2025, 5, 15)

    result = Duration.new(@membership, preference_date).calculate

    assert_equal preference_date, result[:start_date]
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end

  test "institutional custom duration (45 days) does not round up" do
    # FIX: Modifichiamo l'oggetto in memoria invece di usare 'stubs'
    @course.duration_days = 45

    preference_date = Date.new(2025, 1, 10)
    result = Duration.new(@course, preference_date).calculate

    # Deve finire esattamente dopo 45 giorni (inclusivo)
    # 10 Gennaio + 44 giorni = 23 Febbraio
    assert_equal Date.new(2025, 2, 23), result[:end_date]
  end

  test "institutional one day pass" do
    # FIX: Modifichiamo l'oggetto in memoria
    @course.duration_days = 1

    preference_date = Date.new(2025, 1, 10)
    result = Duration.new(@course, preference_date).calculate

    # Inizia e finisce lo stesso giorno
    assert_equal preference_date, result[:start_date]
    assert_equal preference_date, result[:end_date]
  end

  test "leap year handling (29 Feb)" do
    # Scenario: 30 Gennaio in anno bisestile (2024)
    # Il prodotto dura 30 giorni.
    preference_date = Date.new(2024, 1, 30)

    result = Duration.new(@course, preference_date).calculate

    # FIX LOGICO:
    # 30 Gen + 1 Mese (advance) = 29 Feb.
    # .yesterday (regola inclusiva) = 28 Feb.
    # Controllo matematico: 30 Gen, 31 Gen (2gg) + 1..28 Feb (28gg) = 30 Giorni esatti.
    # Quindi il sistema è corretto, scade il 28.

    expected = Date.new(2024, 2, 28)
    assert_equal expected, result[:end_date]
  end
end
