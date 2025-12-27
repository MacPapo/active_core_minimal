class Preferences::ThemesController < Preferences::BaseController
  def show
    render_preference("theme")
  end

  def update
    theme = params.require(:theme)
    allowed = UserPreferences::ALLOWED_THEMES
    return head :bad_request unless allowed.include?(theme)

    update_preference!("theme", theme)
    render_preference("theme")
  end
end
