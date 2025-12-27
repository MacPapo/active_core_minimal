class DashboardController < ApplicationController
  def index
    # 1. Situazione Cassa (Value Object Ottimizzato)
    @daily_cash = DailyCash.current

    # 2. Ultimi Ingressi
    @recent_accesses = AccessLog.includes(:member)
                                .where("entered_at >= ?", Date.current.beginning_of_day)
                                .order(entered_at: :desc)
                                .limit(5)

    # 3. Scadenze
    @expiring_count = Subscription.kept
                                  .where(end_date: Date.current..7.days.from_now)
                                  .count
  end
end
