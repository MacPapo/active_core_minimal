class Disciplines::MembersController < ApplicationController
  before_action :set_discipline

  def index
    product_ids = @discipline.product_ids

    all_subs = Subscription.kept
                 .where(product_id: product_ids)
                 .where("end_date >= ?", 30.days.ago)
                 .includes(:member, :product)
    @subscriptions = all_subs.group_by(&:member_id)
                       .map { |_, subs| subs.max_by(&:end_date) }
                       .sort_by(&:end_date)
  end

  private
    def set_discipline
      @discipline = Discipline.find(params[:discipline_id])
    end
end
