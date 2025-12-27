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

    # SCENARIO 1: Arrivo dal profilo di un membro (param ?member_id=123)
    if params[:member_id]
      @member = Member.find(params[:member_id])
      @sale.member = @member
    end

    # SCENARIO 2: Rinnovo Abbonamento (param ?renew_subscription_id=456)
    # Questa è la Killer Feature: pre-compila prodotto e prezzo
    if params[:renew_subscription_id] && @member
      old_sub = @member.subscriptions.find(params[:renew_subscription_id])
      @sale.product = old_sub.product
      @sale.amount = old_sub.product.price # Prezzo attuale del prodotto

      # Logica continuità: Se scade in futuro, il nuovo parte dopo la scadenza.
      # Se è già scaduto, parte oggi.
      # (Questo valore andrebbe passato a un campo hidden o usato nel SubscriptionIssuer)
      @suggested_start_date = [ old_sub.end_date + 1.day, Date.current ].max
    else
      @suggested_start_date = Date.current
    end
  end

  def create
    @sale = Sale.new(sale_params)
    @sale.user = current_user # Forza l'utente corrente come cassiere

    # Se non è stato selezionato manualmente un prezzo, usa quello del prodotto
    if @sale.product && (@sale.amount.nil? || @sale.amount.zero?)
      @sale.amount = @sale.product.price
    end

    if @sale.save
      # Redirect alla show per stampare subito la ricevuta o tornare al membro
      redirect_to sale_path(@sale), notice: t(".created", default: "Vendita registrata con successo.")
    else
      # Se fallisce, ricarica il membro per la view
      @member = @sale.member
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    # Soft delete (annulla vendita)
    if @sale.discard
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
        :subscription_start_date
      )
    end
end
