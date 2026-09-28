require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  test "requires a name" do
    assert_not lists(:one).categories.build(name: " ").valid?
  end

  test "name is unique within a list but not across lists" do
    assert_not lists(:one).categories.build(name: "Home").valid?
    assert lists(:two).categories.build(name: "Home").valid?
  end

  test "color must be a six digit hex code" do
    category = categories(:one)

    category.color = "#A5f3fc"
    assert category.valid?

    [ "a5f3fc", "#fff", "red", "#a5f3fc; background: url(x)" ].each do |color|
      category.color = color
      assert_not category.valid?, "#{color.inspect} should be invalid"
    end
  end
end
