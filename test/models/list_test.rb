require "test_helper"

class ListTest < ActiveSupport::TestCase
  test "the default for new tasks is the first category" do
    list = lists(:one)

    assert_equal categories(:one), list.category_for_new_tasks
    list.reorder_categories([ categories(:two).id, categories(:one).id ])
    assert_equal categories(:two), list.reload.category_for_new_tasks
  end
end
