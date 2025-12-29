require "test_helper"

class RenewalCalculatorTest < ActiveSupport::TestCase
  # TimeHelpers per fissare "Oggi" durante i test
  include ActiveSupport::Testing::TimeHelpers

  setup do
    @member = members(:alice)
    @product = products(:yoga_monthly) # Mensile (30gg) -> Logica Calendario

    # Puliamo eventuali sottoscrizioni esistenti per partire da zero
    @member.subscriptions.destroy_all
  end

  test "returns dates starting today (snapped) if no history exists" do
    # Scenario: Prima iscrizione assoluta il 20 Gennaio
    today = Date.new(2025, 1, 20)

    travel_to today do
      calculator = RenewalCalculator.new(@member, @product)
      result = calculator.call

      # LOGICA:
      # 1. Raw Start: Oggi (20 Gennaio)
      # 2. Duration Snap: 1° Gennaio
      assert_equal Date.new(2025, 1, 1), result[:start_date]
      assert_equal Date.new(2025, 1, 31), result[:end_date]
    end
  end

  test "continuity: anticipated renewal snaps to next month start" do
    # Scenario: Oggi 20 Gennaio. Scadenza attuale 31 Gennaio.
    today = Date.new(2025, 1, 20)
    current_expiry = Date.new(2025, 1, 31)

    travel_to today do
      create_subscription(end_date: current_expiry)

      calculator = RenewalCalculator.new(@member, @product)
      result = calculator.call

      # LOGICA:
      # 1. Raw Start (Continuità): 1° Febbraio
      # 2. Duration Snap: 1° Febbraio (già inizio mese) -> Invariato
      assert_equal Date.new(2025, 2, 1), result[:start_date]
      assert_equal Date.new(2025, 2, 28), result[:end_date]
    end
  end

  test "continuity: small gap (punishment) snaps to GAP month start" do
    # Scenario: Oggi 20 Gennaio. Scaduto il 5 Gennaio (Gap 15gg < 30gg Grace).
    today = Date.new(2025, 1, 20)
    past_expiry = Date.new(2025, 1, 5)

    travel_to today do
      create_subscription(end_date: past_expiry)

      calculator = RenewalCalculator.new(@member, @product)
      result = calculator.call

      # LOGICA:
      # 1. Raw Start (Continuità punitiva): 6 Gennaio
      # 2. Duration Snap: 6 Gennaio appartiene a Gennaio -> 1° Gennaio
      # Risultato: Paghi tutto Gennaio anche se rinnovi il 20.
      assert_equal Date.new(2025, 1, 1), result[:start_date]
      assert_equal Date.new(2025, 1, 31), result[:end_date]
    end
  end

  test "reset: huge gap snaps to CURRENT month start" do
    # Scenario: Oggi 20 Gennaio. Scaduto a Ottobre (Gap enorme).
    today = Date.new(2025, 1, 20)
    past_expiry = Date.new(2024, 10, 31)

    travel_to today do
      create_subscription(end_date: past_expiry)

      calculator = RenewalCalculator.new(@member, @product)
      result = calculator.call

      # LOGICA:
      # 1. Raw Start (Reset): Oggi (20 Gennaio)
      # 2. Duration Snap: 20 Gennaio -> 1° Gennaio
      assert_equal Date.new(2025, 1, 1), result[:start_date]
      assert_equal Date.new(2025, 1, 31), result[:end_date]
    end
  end

  private

  def create_subscription(end_date:)
    # Creiamo un abbonamento fittizio nel DB per simulare lo storico
    start_date = end_date.beginning_of_month
    Subscription.create!(
      member: @member,
      product: @product,
      start_date: start_date,
      end_date: end_date,
      sale: Sale.create!(member: @member, user: users(:staff), product: @product, sold_on: start_date)
    )
  end
end
