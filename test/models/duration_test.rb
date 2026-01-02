require "test_helper"

class DurationTest < ActiveSupport::TestCase
  setup do
    @course = products(:yoga_monthly)        # Istituzionale (30gg di default)
    @membership = products(:annual_membership) # Associativo (365gg)
  end

  # --- TEST 1: LOGICA MENSILE (Invariata) ---
  # Il mensile continua a fare "Snap" al 1° del mese e rispettare l'anno sportivo
  # per sicurezza (salvo diversa indicazione).

  test "institutional monthly SNAPS to beginning of month" do
    # Scenario: Pago il 20 Gennaio
    preference_date = Date.new(2025, 1, 20)

    result = Duration.new(@course, preference_date).calculate

    # Regola: Inizia il 1° del mese
    assert_equal Date.new(2025, 1, 1), result[:start_date]
    # Regola: Finisce a fine mese
    assert_equal Date.new(2025, 1, 31), result[:end_date]
  end

  test "institutional monthly CAPS at Sport Year End" do
    # Scenario: Corso mensile comprato il 15 Agosto 2025 (Anno sportivo finisce il 31/08)
    preference_date = Date.new(2025, 8, 15)

    result = Duration.new(@course, preference_date).calculate

    # Inizia il 1° Agosto
    assert_equal Date.new(2025, 8, 1), result[:start_date]
    # Si ferma al 31 Agosto (Fine anno sportivo)
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end

  # --- TEST 2: NUOVA LOGICA TRIMESTRALE (90gg) ---
  # Deve fare lo Snap al 1°, ma PUÒ USCIRE dall'anno sportivo.

  test "institutional quarterly SNAPS and CROSSES Sport Year boundary" do
    # Trasformiamo il prodotto in un Trimestrale
    @course.duration_days = 90

    # Scenario: Acquisto il 15 Luglio 2025.
    # Anno sportivo finisce il 31 Agosto.
    # Trimestre: Luglio, Agosto, Settembre (sfora Agosto).
    preference_date = Date.new(2025, 7, 15)

    result = Duration.new(@course, preference_date).calculate

    # Regola: Snap al 1° Luglio
    assert_equal Date.new(2025, 7, 1), result[:start_date]

    # Regola: 3 mesi interi (Lug, Ago, Set) -> Fine 30 Settembre
    # DEVE ignorare il blocco del 31 Agosto
    assert_equal Date.new(2025, 9, 30), result[:end_date]
  end

  # --- TEST 3: NUOVA LOGICA ANNUALE (365gg) ---
  # Rolling puro. Data esatta -> Data esatta. Ignora anno sportivo.

  test "institutional annual uses ROLLING logic and IGNORES Sport Year" do
    # Trasformiamo il prodotto in un Annuale Istituzionale (es. Sala Pesi Open)
    @course.duration_days = 365

    # Scenario: Acquisto il 14 Maggio 2025
    preference_date = Date.new(2025, 5, 14)

    result = Duration.new(@course, preference_date).calculate

    # Regola Rolling: Parte il giorno esatto dell'acquisto (niente snap)
    assert_equal Date.new(2025, 5, 14), result[:start_date]

    # Regola Rolling: Finisce esattamente un anno dopo (meno un giorno)
    # Scavalca tranquillamente il 31 Agosto
    assert_equal Date.new(2026, 5, 13), result[:end_date]
  end

  # --- TEST 4: LOGICA GIORNI PURI (Custom) ---

  test "institutional custom duration (45 days) uses PURE DAYS logic with Cap" do
    @course.duration_days = 45

    # Se non specificato diversamente in duration.rb, i custom days rispettano ancora il Cap
    # Scenario: 10 Gennaio
    preference_date = Date.new(2025, 1, 10)
    result = Duration.new(@course, preference_date).calculate

    assert_equal Date.new(2025, 1, 10), result[:start_date]
    # 10 Gen + 45gg = 23 Feb
    assert_equal Date.new(2025, 2, 23), result[:end_date]
  end

  # --- TEST 5: LOGICA ASSOCIATIVA (Invariata) ---

  test "associative membership ALWAYS CAPS at Sport Year End" do
    # La quota associativa deve morire il 31 Agosto, cascasse il mondo.
    preference_date = Date.new(2025, 5, 15)

    result = Duration.new(@membership, preference_date).calculate

    assert_equal preference_date, result[:start_date]
    assert_equal Date.new(2025, 8, 31), result[:end_date]
  end
end
