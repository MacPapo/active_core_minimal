module Themable
  extend ActiveSupport::Concern

  included do
    before_action :load_theme
  end

  private
    def load_theme
      return @theme = current_user.theme_or_default if current_user

      @theme = "light"
    end
end
