# frozen_string_literal: true

class Duration
  attr_reader :product, :preference_date

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
      {
        start_date: preference_date,
        end_date: SportYear.end_date_for(preference_date)
      }
    end

    def calculate_institutional
      effective_start = preference_date

      if product.duration_days < 30
        # Giorni esatti
        theoretical_end = effective_start.advance(days: product.duration_days - 1)
      else
        # Mesi mobili (es. 20 Gen -> 19 Feb)
        months_to_add = (product.duration_days / 30.0).round
        theoretical_end = effective_start.advance(months: months_to_add).yesterday
      end

      # Il muro del 31 Agosto (SportYear) rimane valido ed è corretto!
      limit_date = SportYear.end_date_for(effective_start)
      final_end = [ theoretical_end, limit_date ].min

      { start_date: effective_start, end_date: final_end }
    end
end
