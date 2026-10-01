require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = lists(:one)
    @home = categories(:one)
    @work = categories(:two)
    sign_in_as users(:one)
  end

  test "new tasks use the chosen default category, not one named Work" do
    patch make_default_list_category_url(@list, @home)
    assert_redirected_to edit_list_url(@list)

    post list_tasks_url(@list), params: { task: { description: "Water plants" } }

    assert_equal @home, @list.tasks.last.category
  end

  test "settings show which category is the default" do
    get edit_list_url(@list)

    assert_select "##{ActionView::RecordIdentifier.dom_id(@work)} [title='Default for new tasks']"
    assert_select "##{ActionView::RecordIdentifier.dom_id(@home)} button[title='Make default for new tasks']"
  end

  test "can't make another list's category the default" do
    patch make_default_list_category_url(@list, categories(:three))

    assert_response :not_found
    assert_equal @work, @list.reload.default_category
  end

  test "deleting the default category hands the default and its tasks to another category" do
    task = @list.tasks.create!(description: "Report", category: @work)

    delete list_category_url(@list, @work), as: :turbo_stream

    assert_equal @home, @list.reload.default_category
    assert_equal @home, task.reload.category
    assert_select "turbo-stream[action=replace][target=#{ActionView::RecordIdentifier.dom_id(@home)}]"
  end

  test "deleting another category moves its tasks to the default" do
    task = @list.tasks.create!(description: "Garden", category: @home)

    delete list_category_url(@list, @home)

    assert_equal @work, task.reload.category
    assert_equal @work, @list.reload.default_category
  end

  test "new lists default to Work" do
    list = users(:one).lists.create!(name: "Fresh", owner: users(:one))

    assert_equal "Work", list.default_category.name
  end
end
