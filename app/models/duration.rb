# frozen_string_literal: true

class Duration
  attr_reader :product, :preference_date

  COMMERCIAL_MONTH_DAYS = 30

  def initialize(product, preference_date = Date.current)
    @product = product
    @preference_date = preference_date.to_date
  end

  def calculate
    if product.associative?
      calculate_associative
    else
      calculate_institutional
    end
  end

  private

    def calculate_associative
      # Regola ASD: Scade sempre al 31/08, non importa quando ti iscrivi
      {
        start_date: preference_date,
        end_date: SportYear.end_date_for(preference_date)
      }
    end

    def calculate_institutional
      effective_start = preference_date

      # --- LOGICA ESPLICITA ---
      # Qui decidiamo esplicitamente come trattare le durate.
      # Usiamo 'case' per gestire i pacchetti standard come "Mesi di Calendario"
      # e tutto il resto come "Giorni esatti".

      theoretical_end =
        case product.duration_days
        when 30
          # 1 Mese esatto (Es. 15 Gen -> 14 Feb)
          effective_start.advance(months: 1)
        when 90
          # 3 Mesi esatti (Trimestrale)
          effective_start.advance(months: 3)
        when 180
          # 6 Mesi esatti (Semestrale)
          effective_start.advance(months: 6)
        when 365, 366
          # 1 Anno esatto
          effective_start.advance(years: 1)
        else
          # Caso Fallback: (Es. 45 giorni, 1 giorno, 7 giorni)
          # Aggiungiamo i giorni puri.
          effective_start.advance(days: product.duration_days)
        end

      # --- CORREZIONE INCLUSIVA ---
      # Advance ti porta al "giorno dopo" la scadenza matematica.
      # Esempio: 1 Gennaio + 1 Mese = 1 Febbraio.
      # Ma se pago per Gennaio, il mio abbonamento finisce il 31 Gennaio.
      # Quindi togliamo sempre 1 giorno.
      final_theoretical_end = theoretical_end.yesterday

      # --- IL MURO DI AGOSTO ---
      # Nessun corso istituzionale può sopravvivere alla fine dell'anno sportivo
      limit_date = SportYear.end_date_for(effective_start)
      final_end = [ final_theoretical_end, limit_date ].min

      { start_date: effective_start, end_date: final_end }
    end
end
