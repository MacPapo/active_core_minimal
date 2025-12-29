class RenewalCalculator
  GRACE_PERIOD_DAYS = 30

  # Aggiungiamo options con default vuoto
  def initialize(member, product, reference_date = Date.current, options = {})
    @member = member
    @product = product
    @reference_date = reference_date
    @manual_override = options[:manual_override] # <--- NUOVO FLAG
  end

  def call
    return {} unless @member && @product

    raw_start_date = calculate_start_date

    return {} unless raw_start_date

    # Passiamo raw_start_date alla Duration.
    # Se Duration ha logiche di "Snap al 1° del mese", quelle dipendono dalla classe Duration (che non vedo qui),
    # ma almeno qui gli passiamo la TUA data.
    duration_result = Duration.new(@product, raw_start_date).calculate
    duration_result
  end

  private

  def calculate_start_date
    # 1. SE È UN OVERRIDE MANUALE (dal form), USIAMO SUBITO LA DATA DI RIFERIMENTO
    # Ignoriamo completamente la storia degli abbonamenti passati.
    return @reference_date if @manual_override

    # --- SOTTO: LOGICA AUTOMATICA (solo se non l'hai forzata tu) ---
    last_sub = @member.subscriptions.kept
                          .where(product: @product)
                          .order(end_date: :desc)
                          .first

    return @reference_date unless last_sub

    continuity_date = last_sub.end_date + 1.day
    gap_days = (@reference_date - continuity_date).to_i

    if gap_days < 0
      # Anticipo
      continuity_date
    elsif gap_days <= GRACE_PERIOD_DAYS
      # Recupero (Backdate)
      continuity_date
    else
      # Buco Enorme
      @reference_date
    end
  end
end
