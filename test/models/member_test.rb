require "test_helper"

class MemberTest < ActiveSupport::TestCase
  def setup
    @member = Member.new(
      first_name: "  mario  ",
      last_name: "ROSSI",
      fiscal_code: "rssmra80a01h501z",
      birth_date: "1980-01-01",
      email_address: "  MARIO@test.com "
    )
  end

  test "normalization cleans data automatically" do
    @member.save!

    assert_equal "Mario", @member.first_name
    assert_equal "Rossi", @member.last_name
    assert_equal "mario@test.com", @member.email_address
    assert_equal "RSSMRA80A01H501Z", @member.fiscal_code # Upcase fondamentale
  end

  test "virtual column full_name works" do
    @member.save!
    # Rileggiamo dal DB per attivare la colonna virtuale
    reloaded = Member.find(@member.id)
    assert_equal "Mario Rossi", reloaded.full_name
  end

  test "enforces fiscal_code uniqueness only for kept records" do
    @member.save!

    # 1. Prova a creare un duplicato (deve fallire)
    duplicate = @member.dup
    assert_not duplicate.valid?
    assert_includes duplicate.errors[:fiscal_code], "has already been taken"

    # 2. Cestina il primo socio
    @member.discard!

    # 3. Ora il duplicato deve essere valido (perché il primo è 'morto')
    assert duplicate.valid?
  end

  test "prevents deletion if sales exist" do
    @member.save!
    assert_respond_to @member, :sales
    reflection = Member.reflect_on_association(:sales)
    assert_equal :restrict_with_error, reflection.options[:dependent]
  end
end
