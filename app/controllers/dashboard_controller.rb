class DashboardController < ApplicationController
  def index
    @daily_cash = DailyCash.current

    @recent_sales = Sale.kept
                        .includes(:member, :product, :user)
                        .order(created_at: :desc)
                        .limit(10)

    @expiring_count = Subscription.kept
                                  .where(end_date: Date.current..7.days.from_now)
                                  .count
  end
end
