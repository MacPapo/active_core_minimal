class Preferences::LanguagesController < Preferences::BaseController
  def update
    lang = params.require(:language) # Il parametro dal form può restare "language"
    allowed = I18n.available_locales.map(&:to_s)
    return head :bad_request unless allowed.include?(lang)

    I18n.locale = lang

    update_preference!("locale", lang)
    render_preference("locale")
  end
end
