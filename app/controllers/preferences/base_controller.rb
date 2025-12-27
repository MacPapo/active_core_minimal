class Preferences::BaseController < ApplicationController
  protected
    def update_preference!(key, value)
      current_user.update!(preferences: current_user.preferences.merge(key => value))
    end

    def render_preference(key)
      render json: { key => current_user.preferences[key] }
    end
end
