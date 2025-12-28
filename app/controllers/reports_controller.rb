class ReportsController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : Date.current
    @month_range = @date.beginning_of_month..@date.end_of_month

    # 1. QUERY UNICA: Scarichiamo tutte le vendite cash del mese in un colpo solo.
    #    Usiamo .includes(:member) se nella vista mostrassimo i nomi, ma qui servono solo i totali.
    monthly_sales = Sale.kept
                        .where(sold_on: @month_range, payment_method: :cash)
                        .order(:created_at)

    # 2. RAGGRUPPAMENTO: Creiamo un Hash { Data => [Sale, Sale...], Data2 => [...] }
    sales_by_date = monthly_sales.group_by(&:sold_on)

    # 3. MAPPING: Creiamo i DailyCash passando i dati già pronti
    @daily_reports = @month_range.map do |date|
      # Passiamo l'array di vendite per quel giorno (o array vuoto se nil)
      DailyCash.for(date, sales: sales_by_date[date] || [])
    end
  end

  def show
    @date = Date.parse(params[:date])

    case params[:report_type]
    when "daily_cash"
      daily_sales = Sale.kept
                      .where(sold_on: @date, payment_method: :cash)
                      .includes(:member)
                      .order(:created_at)

      @daily_cash = DailyCash.for(@date, sales: daily_sales)
    else
      redirect_to reports_path, alert: "Tipo di report non valido."
    end
  end
end
