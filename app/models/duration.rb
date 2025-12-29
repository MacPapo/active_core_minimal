# frozen_string_literal: true

class Duration
  attr_reader :product, :preference_date

  # Mappa i giorni ai mesi logici.
  # Se un prodotto ha questa durata esatta, applichiamo la logica "Calendario".
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
      months_count = CALENDAR_DURATIONS[product.duration_days]

      if months_count
        # È un pacchetto "Solare" (Mensile, Trimestrale...) -> SNAP AL CALENDARIO
        calculate_calendar_aligned(months_count)
      else
        # È un pacchetto "a giorni" (es. Settimanale) -> CONTEGGIO PURO
        calculate_days_pure
      end
    end

    def calculate_calendar_aligned(months)
      # 1. SNAP START: Qualsiasi data arrivi (es. 15 Gennaio), forziamo al 1° del mese.
      effective_start = preference_date.beginning_of_month

      # 2. CALCOLO FINE: Aggiungiamo i mesi e prendiamo l'ultimo giorno del mese risultante.
      # Es. Mensile (1 mese): 01/01 + (1-1) mesi = Gennaio -> Fine mese = 31/01
      # Es. Trimestrale (3 mesi): 01/01 + (3-1) mesi = Marzo -> Fine mese = 31/03
      theoretical_end = effective_start.advance(months: months - 1).end_of_month

      apply_sport_year_limit(effective_start, theoretical_end)
    end

    def calculate_days_pure
      effective_start = preference_date
      # Es. 7 giorni: 1 Gen + 7 giorni = 8 Gen. Yesterday = 7 Gen.
      theoretical_end = effective_start.advance(days: product.duration_days).yesterday

      apply_sport_year_limit(effective_start, theoretical_end)
    end

    def apply_sport_year_limit(start_date, end_date)
      limit_date = SportYear.end_date_for(start_date)
      final_end = [ end_date, limit_date ].min

      { start_date: start_date, end_date: final_end }
    end
end
