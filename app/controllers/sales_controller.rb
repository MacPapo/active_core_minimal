class SalesController < ApplicationController
  before_action :require_admin, only: [ :index ]
  before_action :set_sale, only: [ :show, :destroy ]

  def index
    scope = Sale.kept
                 .includes(:member, :user)
                 .order(sold_on: :desc, created_at: :desc)
    @pagy, @sales = pagy(scope)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        pdf = PaymentReceiptPdf.new(@sale)
        send_data pdf.render,
                  filename: "ricevuta_#{@sale.id}_#{@sale.member.last_name}.pdf",
                  type: "application/pdf",
                  disposition: "inline"
      end
    end
  end

  def new
    @sale = Sale.new(sold_on: Date.current, user: current_user)
    @sale.build_subscription(start_date: Date.current)

    if params[:member_id]
      @sale.member = Member.find(params[:member_id])
    end

    setup_renewal_data if params[:renew_subscription_id]
  end

  def create
    @sale = Sale.new(sale_params)
    @sale.user = current_user

    if @sale.save
      redirect_to sale_path(@sale), notice: t(".created", default: "Vendita registrata con successo.")
    else
      @sale.build_subscription(start_date: Date.current) if @sale.subscription.nil?
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @sale.discard!
      redirect_back(fallback_location: sales_path, status: :see_other, notice: "Vendita annullata/stornata.")
    else
      redirect_back(fallback_location: sales_path, status: :see_other, alert: "Impossibile annullare la vendita.")
    end
  end

  private
    def set_sale
      @sale = Sale.find(params[:id])
    end

    def setup_renewal_data
      return unless @sale.member && params[:renew_subscription_id]

      old_sub = @sale.member.subscriptions.find(params[:renew_subscription_id])

      @sale.product = old_sub.product
      @sale.amount  = old_sub.product.price || 0

      dates = RenewalCalculator.new(@sale.member, @sale.product, Date.current).call

      @sale.subscription.start_date = dates[:start_date]
      @sale.subscription.end_date   = dates[:end_date]
    end

    def sale_params
      params.require(:sale).permit(
        :member_id,
        :product_id,
        :amount,
        :payment_method,
        :sold_on,
        :notes,
        subscription_attributes: [ :start_date ]
      )
    end
end
