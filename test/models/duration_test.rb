require "test_helper"

class DurationTest < ActiveSupport::TestCase
  setup do
    @course = products(:yoga_monthly)        # Istituzionale (30gg)
    @membership = products(:annual_membership) # Associativo (365gg)
  end

  # --- TEST LOGICA CALENDARIO (Mensili, Trimestrali...) ---

  test "institutional monthly SNAPS to beginning of month" do
    # Scenario: Pago il 20 Gennaio per un Mensile
    preference_date = Date.new(2025, 1, 20)

    # Calcolo
    result = Duration.new(@course, preference_date).calculate

    # NUOVA REGOLA: Deve iniziare il 1° del mese
    assert_equal Date.new(2025, 1, 1), result[:start_date]

    # NUOVA REGOLA: Finisce alla fine del mese corrente
    assert_equal Date.new(2025, 1, 31), result[:end_date]
  end

  test "institutional caps at Sport Year End (with Snap)" do
    # Scenario: Corso mensile comprato il 15 Agosto 2025
    preference_date = Date.new(2025, 8, 15)

    result = Duration.new(@course, preference_date).calculate

    # Regola Snap: Inizia il 1° Agosto
    assert_equal Date.new(2025, 8, 1), result[:start_date]

    # Regola Anno Sportivo: Deve fermarsi al 31 Agosto (coincide con fine mese)
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end

  test "leap year handling (Feb Calendar Snap)" do
    # Scenario: Acquisto un mensile il 10 Febbraio 2024 (Bisestile)
    preference_date = Date.new(2024, 2, 10)

    result = Duration.new(@course, preference_date).calculate

    # Snap al 1° Febbraio
    assert_equal Date.new(2024, 2, 1), result[:start_date]

    # Fine mese Febbraio bisestile -> 29 Febbraio
    assert_equal Date.new(2024, 2, 29), result[:end_date]
  end

  # --- TEST LOGICA GIORNI PURI (Settimanali, Giornalieri...) ---
  # Questi non devono fare lo snap, perché 7 o 45 giorni non sono mesi standard.

  test "institutional custom duration (45 days) uses PURE DAYS logic" do
    # FIX: Modifichiamo l'oggetto in memoria
    @course.duration_days = 45 # 45 non è nella lista CALENDAR_DURATIONS

    preference_date = Date.new(2025, 1, 10)
    result = Duration.new(@course, preference_date).calculate

    # Qui NON deve fare snap al 1° Gennaio, ma partire dal 10.
    assert_equal Date.new(2025, 1, 10), result[:start_date]

    # 10 Gennaio + 45 giorni = 23 Febbraio (incluso start)
    # Logica: 10 Gen + 45gg = 24 Feb. Yesterday = 23 Feb.
    assert_equal Date.new(2025, 2, 23), result[:end_date]
  end

  test "institutional one day pass uses PURE DAYS logic" do
    @course.duration_days = 1 # 1 non è nella lista CALENDAR_DURATIONS

    preference_date = Date.new(2025, 1, 10)
    result = Duration.new(@course, preference_date).calculate

    assert_equal preference_date, result[:start_date]
    assert_equal preference_date, result[:end_date]
  end

  # --- TEST ASSOCIATIVO ---

  test "associative covers full sport year" do
    # Scenario: Iscrizione il 15 Maggio 2025
    preference_date = Date.new(2025, 5, 15)

    result = Duration.new(@membership, preference_date).calculate

    # L'associativo parte sempre dalla data di pagamento (o si può discutere, ma di solito è così)
    assert_equal preference_date, result[:start_date]
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end
end
