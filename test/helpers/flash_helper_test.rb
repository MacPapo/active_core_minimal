require "test_helper"

class FlashHelperTest < ActionView::TestCase
  test "flash_class returns correct tailwind classes for standard types" do
    # Notice -> Verde
    assert_match /alert-success/, flash_class(:notice)
    assert_match /text-white/, flash_class(:notice)

    # Alert -> Rosso
    assert_match /alert-error/, flash_class(:alert)
  end

  test "flash_class handles symbol and string keys" do
    assert_equal flash_class(:notice), flash_class("notice")
  end

  test "flash_class returns default info class for unknown types" do
    assert_match /alert-info/, flash_class(:banana)
  end

  test "flash_class handles explicit success and warning types" do
    # Utile se imposti flash[:success] o flash[:warning] manualmente nei controller
    assert_match /alert-success/, flash_class(:success)
    assert_match /alert-warning/, flash_class(:warning)
  end
end
