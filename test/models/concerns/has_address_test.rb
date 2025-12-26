require "test_helper"

class HasAddressTest < ActiveSupport::TestCase
  test "normalizes dirty inputs on assignment" do
    bob = members(:bob)
    bob.address = "  piazza navona 1  "
    bob.city = "  roma  "
    bob.zip_code = " I-00100 ! "

    assert_equal "Piazza Navona 1", bob.address
    assert_equal "Roma", bob.city
    assert_equal "00100", bob.zip_code
  end

  test "full_address_ruby helper joins existing parts" do
    bob = members(:bob)
    assert_equal "Roma", bob.full_address_ruby

    bob.address = "Via del Corso"
    bob.zip_code = "00186"
    assert_equal "Via Del Corso, Roma, 00186", bob.full_address_ruby
  end

  test "full_address_ruby handles complete data" do
    alice = members(:alice)
    expected = "Via Roma 1, Milano, 20100"
    assert_equal expected, alice.full_address_ruby
  end
end
