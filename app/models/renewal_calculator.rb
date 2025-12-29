class RenewalCalculator
  GRACE_PERIOD_DAYS = 30

  def initialize(member, product, reference_date = Date.current)
    @member = member
    @product = product
    @reference_date = reference_date
  end

  def call
    return {} unless @member && @product

    start_date = calculate_start_date

    end_date = nil
    if start_date
      duration_result = Duration.new(@product, start_date).calculate
      end_date = duration_result[:end_date]
    end

    { start_date: start_date, end_date: end_date }
  end

  private
    def calculate_start_date
      last_sub = @member.subscriptions.kept
                        .where(product: @product)
                        .order(end_date: :desc)
                        .first

      return @reference_date unless last_sub

      continuity_date = last_sub.end_date + 1.day
      gap_days = (@reference_date - continuity_date).to_i

      if gap_days < 0
        # Anticipo: Mantieni continuità futura
        continuity_date
      elsif gap_days <= GRACE_PERIOD_DAYS
        # Recupero/Punizione: Mantieni continuità passata (Backdate)
        continuity_date
      else
        # Buco Enorme: Reset a oggi
        @reference_date
      end
    end
end
