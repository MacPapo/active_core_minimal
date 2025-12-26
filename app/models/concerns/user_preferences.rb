module UserPreferences
  extend ActiveSupport::Concern

  ALLOWED_THEMES = %w[light dark cupcake bumblebee emerald corporate synthwave retro cyberpunk valentine halloween garden forest aqua lofi pastel fantasy wireframe black luxury dracula cmyk autumn business acid lemonade night coffee winter dim nord sunset caramellate abyss silk].freeze

  included do
    store_accessor :preferences, :theme, :locale

    validates :theme, inclusion: { in: ALLOWED_THEMES }, allow_nil: true
    validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s) }, allow_nil: true

    after_initialize :set_default_preferences, if: :new_record?
  end

  def theme_or_default
    theme.presence || "light"
  end

  def locale_or_default
    locale.presence || I18n.default_locale.to_s
  end

  private
    def set_default_preferences
      self.preferences ||= {}
    end
end
