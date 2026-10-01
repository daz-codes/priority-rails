require "test_helper"

class ListTest < ActiveSupport::TestCase
  test "default category must belong to the list" do
    list = lists(:one)
    list.default_category = categories(:three)

    assert_not list.valid?
  end

  test "falls back to the first category when no default is set" do
    list = lists(:one)
    list.update!(default_category: nil)

    assert_equal list.categories.first, list.category_for_new_tasks
  end
end
