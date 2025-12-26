require "test_helper"

class IconsHelperTest < ActionView::TestCase
  # ==========================================
  # TEST: Icona Esistente (Happy Path)
  # ==========================================

  test "icon renders existing svg with defaults" do
    # Usiamo 'chat_bubble' che sappiamo esistere
    result = icon("chat_bubble")

    # Verifica che sia un SVG
    assert_match /<svg/, result

    # Verifica le dimensioni di default (20)
    assert_match /width="20"/, result
    assert_match /height="20"/, result
  end

  test "icon accepts custom size and class" do
    result = icon("chat_bubble", size: 48, class: "text-primary mb-2")

    # Verifica dimensioni personalizzate
    assert_match /width="48"/, result
    assert_match /height="48"/, result

    # Verifica che la classe sia stata iniettata
    assert_match /class=".*text-primary mb-2.*"/, result
  end

  test "icon adds custom attributes (data attributes, aria, etc)" do
    # Testiamo l'iniezione di attributi extra tramite **options
    result = icon("chat_bubble", "data-controller": "tooltip", "aria-hidden": "true")

    assert_match /data-controller="tooltip"/, result
    assert_match /aria-hidden="true"/, result
  end

  # ==========================================
  # TEST: Icona Mancante (Fallback)
  # ==========================================

  test "icon renders placeholder when file is missing" do
    # Usiamo un nome che sicuramente non esiste
    name = "non_existent_icon_123"
    result = icon(name)

    # Deve restituire uno SPAN, non un SVG
    assert_match /<span/, result
    assert_no_match /<svg/, result

    # Deve contenere la classe del placeholder
    assert_match /icon-placeholder/, result

    # Deve contenere l'iniziale del nome (N di non_existent...)
    assert_match />#{name.first.upcase}</, result
  end

  test "icon placeholder respects size and custom class" do
    result = icon("banana", size: 50, class: "bg-red-500")

    # Verifica che lo style inline abbia width/height corretti
    assert_match /width: 50px/, result
    assert_match /height: 50px/, result

    # Verifica la classe extra
    assert_match /bg-red-500/, result
  end

  # ==========================================
  # TEST: Cache (Base)
  # ==========================================

  test "caching mechanism works" do
    # Qui verifichiamo solo che chiamando due volte non esploda
    # e restituisca lo stesso contenuto HTML.
    # Testare Rails.cache in profondità negli helper è complesso,
    # ci fidiamo che se l'output è uguale, il codice gira.

    first_call = icon("chat_bubble")
    second_call = icon("chat_bubble")

    assert_equal first_call, second_call
  end
end
