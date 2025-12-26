require "test_helper"

class UserPreferencesTest < ActiveSupport::TestCase
  def setup
    # Creiamo un utente "pulito" per ogni test
    @user = User.new(
      username: "pref_tester",
      password: "password",
      first_name: "Test",
      last_name: "User",
      email_address: "test@example.com"
    )
  end

  test "initializes with empty preferences hash" do
    # Verifica il callback after_initialize
    assert_not_nil @user.preferences
    assert_equal({}, @user.preferences)
  end

  test "can write and read theme via accessor" do
    # Verifica che store_accessor funzioni
    @user.theme = "dracula"
    assert_equal "dracula", @user.theme

    # Verifica che sia salvato davvero nell'hash JSON
    assert_equal "dracula", @user.preferences["theme"]
  end

  test "validates allowed themes" do
    # Caso Felice
    @user.theme = "cyberpunk"
    assert @user.valid?

    # Caso Errore (Tema non in lista)
    @user.theme = "windows_95_ugly_theme"
    assert_not @user.valid?
    assert_includes @user.errors[:theme], "is not included in the list"

    # Caso Nil (Consentito da allow_nil: true)
    @user.theme = nil
    assert @user.valid?
  end

  test "returns correct theme fallback" do
    # Se nil -> Default ("light")
    @user.theme = nil
    assert_equal "light", @user.theme_or_default

    # Se vuoto -> Default ("light")
    @user.theme = ""
    assert_equal "light", @user.theme_or_default

    # Se settato -> Valore settato
    @user.theme = "dim"
    assert_equal "dim", @user.theme_or_default
  end

  test "validates available locales" do
    # Assumiamo che :it e :en siano disponibili in config/application.rb

    # Caso Felice
    @user.locale = I18n.default_locale.to_s
    assert @user.valid?

    # Caso Errore
    @user.locale = "klingon"
    assert_not @user.valid?
    assert_includes @user.errors[:locale], "is not included in the list"
  end

  test "returns correct locale fallback" do
    default = I18n.default_locale.to_s

    @user.locale = nil
    assert_equal default, @user.locale_or_default

    @user.locale = "it"
    assert_equal "it", @user.locale_or_default
  end

  test "persists preferences to database" do
    @user.theme = "coffee"
    @user.save!

    # Ricarichiamo dal DB per essere sicuri che sia stato salvato nel JSON
    loaded_user = User.find(@user.id)
    assert_equal "coffee", loaded_user.preferences["theme"]
    assert_equal "coffee", loaded_user.theme
  end
end
