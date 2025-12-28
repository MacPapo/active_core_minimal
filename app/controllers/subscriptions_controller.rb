class SubscriptionsController < ApplicationController
  before_action :set_subscription, only: [ :edit, :update, :destroy ]

  def edit; end

  def update
    if @subscription.update(subscription_params)
      redirect_to @subscription.member, notice: "Abbonamento aggiornato."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @subscription.discard!
      redirect_back(fallback_location: @subscription.member, status: :see_other, notice: "Abbonamento e relativa vendita annullati.")
    else
      redirect_back(fallback_location: @subscription.member, status: :see_other, alert: "Impossibile annullare l'abbonamento.")
    end
  end

  private
    def set_subscription
      @subscription = Subscription.find(params[:id])
    end

    def subscription_params
      params.require(:subscription).permit(:start_date, :end_date)
    end
end
