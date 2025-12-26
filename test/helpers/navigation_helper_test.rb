require "test_helper"

class NavigationHelperTest < ActionView::TestCase
  # Helper per simulare la pagina corrente nei test
  def set_current_path(path)
    controller.request.path = path
  end

  test "active_link_to adds menu-active class when on current page" do
    set_current_path("/users")

    # Caso standard
    result = active_link_to("Utenti", "/users")
    assert_match /menu-active/, result

    # Caso non attivo
    result_inactive = active_link_to("Home", "/home")
    assert_no_match /menu-active/, result_inactive
  end

  test "active_link_to supports block syntax" do
    set_current_path("/settings")

    result = active_link_to("/settings") do
      tag.span("Impostazioni")
    end

    assert_match /menu-active/, result
    assert_match /href="\/settings"/, result
    assert_match /<span>Impostazioni<\/span>/, result
  end

  test "active_link_to accepts existing classes" do
    set_current_path("/profile")

    result = active_link_to("Profilo", "/profile", class: "text-lg")

    # Deve mantenere text-lg E aggiungere menu-active
    assert_match /text-lg/, result
    assert_match /menu-active/, result
  end

  # ==========================================
  # TEST DELLE OTTIMIZZAZIONI (Regex & Custom)
  # ==========================================

  test "active_link_to handles regex for subsections" do
    # Siamo dentro una sottosezione di prodotti
    set_current_path("/products/123/edit")

    # Il link punta a /products, ma vogliamo che sia attivo per tutto ciò che è /products...
    result = active_link_to("Prodotti", "/products", active: /^\/products/)

    assert_match /menu-active/, result
  end

  test "active_link_to allows manual override" do
    set_current_path("/nowhere")

    # Forziamo attivo
    result_true = active_link_to("Forced", "/path", active: true)
    assert_match /menu-active/, result_true

    # Forziamo inattivo (anche se fossimo sulla pagina giusta)
    set_current_path("/path")
    result_false = active_link_to("Forced Off", "/path", active: false)
    assert_no_match /menu-active/, result_false
  end
end
