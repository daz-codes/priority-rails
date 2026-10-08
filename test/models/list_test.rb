require "test_helper"

class ListTest < ActiveSupport::TestCase
  test "the default for new tasks is the first category" do
    list = lists(:one)

    assert_equal categories(:one), list.category_for_new_tasks
    list.reorder_categories([ categories(:two).id, categories(:one).id ])
    assert_equal categories(:two), list.reload.category_for_new_tasks
  end

  test "a list that has lost its owner can be managed by its members, and takes one when saved" do
    list = lists(:one)
    list.update_column(:owner_id, nil)

    assert list.owned_by?(users(:two)), "any member, rather than nobody"
    assert list.update(name: "Renamed"), "saving shouldn't fail validation"
    assert_includes list.users, list.reload.owner
  end
end
