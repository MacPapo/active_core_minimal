# app/models/daily_cash.rb
class DailyCash
  # Orario di taglio tra turno mattina e pomeriggio (14:00)
  SPLIT_HOUR = 14

  attr_reader :date

  def initialize(date = Date.current)
    @date = date
  end

  # Factory method per comodità (stile SportYear)
  def self.current
    new(Date.current)
  end

  def self.for(date)
    new(date)
  end

  # --- API PUBBLICA (Restituisce Float/BigDecimal come il tuo Monetizable) ---

  def morning_total
    to_currency(morning_cents)
  end

  def afternoon_total
    to_currency(afternoon_cents)
  end

  def total
    to_currency(total_cents)
  end

  def count
    base_scope.count
  end

  def empty?
    count.zero?
  end

  # --- LOGICA DI AGGREGAZIONE (Memoizzata per performance) ---

  def morning_cents
    @morning_cents ||= base_scope.where("created_at < ?", split_time).sum(:amount_cents)
  end

  def afternoon_cents
    @afternoon_cents ||= base_scope.where("created_at >= ?", split_time).sum(:amount_cents)
  end

  def total_cents
    # Facciamo la somma dei parziali per coerenza matematica,
    # oppure potremmo fare base_scope.sum(:amount_cents)
    morning_cents + afternoon_cents
  end

  private

    # Definiamo il perimetro: Vendite attive, di quel giorno, solo contanti.
    def base_scope
      Sale.kept.where(sold_on: @date, payment_method: :cash)
    end

    # Calcoliamo il timestamp delle 14:00 del giorno in questione.
    # Fondamentale usare in_time_zone per rispettare il fuso orario del server/config.
    def split_time
      @split_time ||= @date.in_time_zone.change(hour: SPLIT_HOUR, min: 0, sec: 0)
    end

    # Helper per convertire i centesimi in unità (Simula il getter di Monetizable)
    def to_currency(cents)
      return 0.0 unless cents
      cents / 100.0
    end
end
