class SalesController < ApplicationController
  before_action :set_sale, only: [ :show, :destroy ]

  def index
    @sales = Sale.kept
                 .includes(:member, :user) # user è chi ha fatto la vendita
                 .order(sold_on: :desc, created_at: :desc)
  end

  def show
    respond_to do |format|
      format.html
      format.pdf do
        render pdf: "ricevuta_#{@sale.receipt_code}",
               template: "sales/receipt",
               layout: "pdf",
               disposition: "inline"
      end
    end
  end

  def new
    @sale = Sale.new
    @sale.sold_on = Date.current
    @sale.user = current_user

    # 1. Inizializziamo l'oggetto Subscription vuoto dentro la Sale
    # Questo è necessario perché nel form useremo 'fields_for :subscription'
    @sale.build_subscription

    if params[:member_id]
      @member = Member.find(params[:member_id])
      @sale.member = @member
    end

    # 2. Logica Rinnovo Intelligente
    if params[:renew_subscription_id] && @member
      old_sub = @member.subscriptions.find(params[:renew_subscription_id])
      @sale.product = old_sub.product
      @sale.amount = old_sub.product.price # Monetizable gestisce questo

      # Calcolo data suggerita
      suggested_start = [ old_sub.end_date + 1.day, Date.current ].max

      # ASSEGNAZIONE ALLA NESTED RELATION
      # Invece di un attributo fake, scriviamo direttamente nell'oggetto figlio
      @sale.subscription.start_date = suggested_start
    else
      # Default: oggi
      @sale.subscription.start_date = Date.current
    end
  end

  def create
    @sale = Sale.new(sale_params)
    @sale.user = current_user

    # Fallback prezzo se vuoto (grazie a Monetizable)
    if @sale.product && (@sale.amount.nil? || @sale.amount.zero?)
      @sale.amount = @sale.product.price
    end

    if @sale.save
      redirect_to sale_path(@sale), notice: t(".created", default: "Vendita registrata con successo.")
    else
      @member = @sale.member
      @sale.build_subscription if @sale.subscription.nil?
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    if @sale.discard!
      redirect_to sales_path, notice: t(".discarded", default: "Vendita annullata/stornata.")
    else
      redirect_to sales_path, alert: t(".error", default: "Impossibile annullare la vendita.")
    end
  end

  private
    def set_sale
      @sale = Sale.find(params[:id])
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
