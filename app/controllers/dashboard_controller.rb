class DashboardController < ApplicationController
  def index
    # 1. Situazione Cassa (Il nostro oggetto magico)
    @daily_cash = DailyCash.new(Date.current)

    # 2. Ultimi Ingressi (Chi c'è in palestra?)
    # Eager loading di member per evitare N+1 query
    @recent_accesses = AccessLog.includes(:member)
                                .where("entered_at >= ?", Date.current.beginning_of_day)
                                .order(entered_at: :desc)
                                .limit(10)

    # 3. Scadenze Imminenti (Opzionale per ora, ma utile)
    @expiring_memberships = Subscription.active.where(end_date: Date.current..1.week.from_now).count
  end
end
