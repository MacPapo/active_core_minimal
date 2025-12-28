class Members::AccessLogsController < ApplicationController
  before_action :set_member

  # TODO
  def index
    @access_logs = @member.access_logs.order(created_at: :desc).limit(100)
  end

  private

  def set_member
    @member = Member.find(params[:member_id])
  end
end
