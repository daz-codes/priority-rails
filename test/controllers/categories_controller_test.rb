require "test_helper"

class CategoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = lists(:one)
    @home = categories(:one)
    @work = categories(:two)
    sign_in_as users(:one)
  end

  test "new tasks go in the first category, which follows the order in settings" do
    post list_tasks_url(@list), params: { task: { description: "Water plants" } }
    assert_equal @home, @list.tasks.last.category

    patch sort_list_categories_url(@list), params: { category_ids: [ @work.id, @home.id ] }, as: :json
    post list_tasks_url(@list), params: { task: { description: "Send report" } }
    assert_equal @work, @list.tasks.last.category
  end

  test "settings explain the default and offer no stars" do
    get edit_list_url(@list)

    assert_select "p", text: /The first category is the default for new tasks/
    assert_select "[title='Make default for new tasks'], [title='Default for new tasks']", count: 0
  end

  test "deleting a category moves its tasks to the first remaining one" do
    garden = @list.tasks.create!(description: "Garden", category: @home)
    report = @list.tasks.create!(description: "Report", category: @work)

    delete list_category_url(@list, @home), as: :turbo_stream
    assert_select "turbo-stream[action=remove][target=#{ActionView::RecordIdentifier.dom_id(@home)}]"
    assert_equal @work, garden.reload.category

    delete list_category_url(@list, @work)
    assert_nil report.reload.category, "no categories left"
  end

  test "new lists start with Work first, so it stays the default" do
    list = users(:one).lists.create!(name: "Fresh", owner: users(:one))

    assert_equal %w[Work Home Hobbies], list.categories.pluck(:name)
    assert_equal "Work", list.category_for_new_tasks.name
  end

  test "categories can be reordered, and the order shows in the filters and task menus" do
    hobbies = @list.categories.create!(name: "Hobbies", color: "#d9f99d")
    assert_equal %w[Home Work Hobbies], @list.categories.pluck(:name), "new categories go last"

    patch sort_list_categories_url(@list), params: { category_ids: [ hobbies.id, @work.id, @home.id ] }, as: :json

    assert_response :ok
    assert_equal %w[Hobbies Work Home], @list.reload.categories.pluck(:name)

    @list.tasks.create!(description: "Thing", category: @home)
    get list_url(@list)
    assert_equal %w[ALL HOBBIES WORK HOME], css_select(".category-pill").map { |pill| pill.text.strip.upcase }
    assert_equal %w[Hobbies Work Home], css_select("select[name='task[category_id]'] option").map { |option| option.text.strip }.first(3)
  end

  test "reordering needs exactly this list's categories" do
    patch sort_list_categories_url(@list), params: { category_ids: [ @home.id ] }, as: :json
    assert_response :unprocessable_entity

    patch sort_list_categories_url(@list), params: { category_ids: [ @home.id, categories(:three).id ] }, as: :json
    assert_response :unprocessable_entity
    assert_equal %w[Home Work], @list.reload.categories.pluck(:name)
  end
end
