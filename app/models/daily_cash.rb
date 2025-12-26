# frozen_string_literal: true

class DailyCash
  # Definiamo lo spartiacque: Le 14:00 sono la fine del turno mattutino
  SPLIT_HOUR = 14

  attr_reader :date

  def initialize(date = Date.current)
    @date = date
    # Carichiamo tutte le vendite IN CONTANTI di quel giorno
    # Usiamo 'includes' se in futuro servirà accedere ai dettagli, per ora basta where
    @sales = Sale.where(sold_on: date, payment_method: :cash)
  end

  # --- MATTINO (00:00 - 13:59) ---
  def morning_sales
    @sales.select { |s| s.created_at.hour < SPLIT_HOUR }
  end

  def morning_total
    # Sommiamo i centesimi (interi) e convertiamo in euro solo alla fine
    cents = morning_sales.sum(&:amount_cents)
    cents / 100.0
  end

  # --- POMERIGGIO (14:00 - 23:59) ---
  def afternoon_sales
    @sales.select { |s| s.created_at.hour >= SPLIT_HOUR }
  end

  def afternoon_total
    cents = afternoon_sales.sum(&:amount_cents)
    cents / 100.0
  end

  # --- TOTALE GIORNATA ---
  def total
    # Sommiamo tutto insieme per evitare errori di arrotondamento sui parziali
    cents = @sales.sum(&:amount_cents)
    cents / 100.0
  end

  def empty?
    @sales.empty?
  end
end
