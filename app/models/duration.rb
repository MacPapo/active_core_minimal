# frozen_string_literal: true

class Duration
  attr_reader :product, :preference_date

  CALENDAR_DURATIONS = {
    30 => 1,   # Mensile
    90 => 3,   # Trimestrale
    180 => 6,  # Semestrale
    365 => 12, # Annuale
    366 => 12  # Bisestile
  }.freeze

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
      # Regola ASD: Scade sempre alla fine dell'anno sportivo
      {
        start_date: preference_date,
        end_date: SportYear.end_date_for(preference_date)
      }
    end

    def calculate_institutional
      case product.duration_days
      when 365, 366
        # NUOVA REGOLA ANNUALE: Rolling puro (Data scelta -> +1 anno)
        # Ignora Anno Sportivo.
        calculate_rolling_annual
      when 90
        # NUOVA REGOLA TRIMESTRALE: Snap al 1° del mese -> +3 mesi
        # Ignora Anno Sportivo.
        months = CALENDAR_DURATIONS[90]
        calculate_calendar_aligned(months, enforce_sport_year: false)
      else
        # ALTRI (es. Mensile, Semestrale):
        # Mantengo la logica vecchia (Snap + Limite Anno Sportivo) per sicurezza?
        # Se vuoi liberare anche loro, metti enforce_sport_year: false
        months_count = CALENDAR_DURATIONS[product.duration_days]
        if months_count
          calculate_calendar_aligned(months_count, enforce_sport_year: true)
        else
          calculate_days_pure(enforce_sport_year: true)
        end
      end
    end

    # --- CALCOLATORI SPECIFICI ---

    def calculate_rolling_annual
      # Iscrizione annuale è dal giorno in cui lo fanno ad 1 anno dopo
      # Esempio: 2 Gennaio 2025 -> 1 Gennaio 2026
      effective_start = preference_date
      theoretical_end = effective_start.advance(years: 1).yesterday

      { start_date: effective_start, end_date: theoretical_end }
    end

    def calculate_calendar_aligned(months, enforce_sport_year: true)
      # Trimestrale: dal primo del mese in cui lo fanno a 3 mesi dopo
      effective_start = preference_date.beginning_of_month

      # Es. 1 Gennaio + (3-1) mesi = Marzo. Fine mese = 31 Marzo.
      theoretical_end = effective_start.advance(months: months - 1).end_of_month

      if enforce_sport_year
        apply_sport_year_limit(effective_start, theoretical_end)
      else
        { start_date: effective_start, end_date: theoretical_end }
      end
    end

    def calculate_days_pure(enforce_sport_year: true)
      effective_start = preference_date
      theoretical_end = effective_start.advance(days: product.duration_days).yesterday

      if enforce_sport_year
        apply_sport_year_limit(effective_start, theoretical_end)
      else
        { start_date: effective_start, end_date: theoretical_end }
      end
    end

    def apply_sport_year_limit(start_date, end_date)
      limit_date = SportYear.end_date_for(start_date)
      # Se la data di inizio è già oltre il limite (es. abbonamento comprato a fine anno per l'anno dopo),
      # bisogna gestire il caso, ma per ora teniamo la logica base:
      final_end = [ end_date, limit_date ].min

      # Safety check: se start > final_end (es. compro oggi ma l'anno è finito ieri),
      # gestire eccezione o ritornare date coerenti?
      # Per ora ci fidiamo che SportYear.end_date_for ritorni la fine dell'anno CORRENTE alla data.

      { start_date: start_date, end_date: final_end }
    end
end
