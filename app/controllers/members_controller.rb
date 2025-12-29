class MembersController < ApplicationController
  before_action :set_member, only: [ :edit, :update, :destroy ]

  def index
    @members = Member.kept
                     .includes(subscriptions: :product)
                     .order(:last_name, :first_name)
  end

  def show
    @member = Member.includes(subscriptions: :product, sales: [])
                    .find(params[:id])
  end

  def renewal_info
    @member = Member.find(params[:id])
    product = Product.find_by(id: params[:product_id])

    if product
      info = @member.renewal_info_for(product)
      render json: info
    else
      render json: {}, status: :bad_request
    end
  end

  def new
    @member = Member.new
  end

  def create
    @member = Member.new(member_params)

    if @member.save
      redirect_to @member, notice: t(".created", default: "Socio creato con successo.")
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @member.update(member_params)
      redirect_to @member, notice: t(".updated", default: "Socio aggiornato con successo.")
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @member.discard!
      redirect_to members_path, status: :see_other, notice: t(".discarded", default: "Socio archiviato correttamente.")
    else
      redirect_to members_path, status: :see_other, alert: t(".discard_error", default: "Impossibile archiviare il socio.")
    end
  end

  private
    def set_member
      @member = Member.find(params[:id])
    end

    def member_params
      params.require(:member).permit(
        :first_name,
        :last_name,
        :fiscal_code,
        :birth_date,
        :email_address,
        :phone,
        :address,
        :city,
        :zip_code,
        :medical_certificate_expiry
      )
    end
end
