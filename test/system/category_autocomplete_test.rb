require "application_system_test_case"

class CategoryAutocompleteTest < ApplicationSystemTestCase
  setup do
    @list = lists(:one) # categories: Home, Work
    @list.tasks.destroy_all
    sign_in_as users(:one)
    visit list_url(@list)
    @input = find("#new_task_form input[name='task[description]']")
  end

  def suggestions = all("[data-category-suggestions] li", visible: true).map(&:text)

  test "typing #w suggests Work, Tab completes it, and the task is added under Work" do
    @input.send_keys("finish report #w")
    assert_selector "[data-category-suggestions] li", text: "#work"
    assert_equal [ "#work" ], suggestions

    @input.send_keys(:tab)
    assert_equal "finish report #work ", @input.value
    assert_no_selector "[data-category-suggestions]", visible: true

    @input.send_keys(:enter)
    assert_selector "#tasks li", text: "finish report"
    task = @list.tasks.reload.last
    assert_equal [ "finish report", categories(:two) ], [ task.description, task.category ]
  end

  test "arrow keys choose between several matches" do
    @list.categories.create!(name: "Hobbies", color: "#d9f99d")
    visit list_url(@list)
    input = find("#new_task_form input[name='task[description]']")

    input.send_keys("paint #h")
    assert_selector "[data-category-suggestions] li", count: 2, text: "#"
    assert_equal [ "#home", "#hobbies" ], suggestions
    input.send_keys(:down, :tab)
    assert_equal "paint #hobbies ", input.value
  end

  test "multi-word categories complete with dashes, and tapping a suggestion works" do
    @list.categories.create!(name: "Side project", color: "#c4b5fd")
    visit list_url(@list)
    input = find("#new_task_form input[name='task[description]']")

    input.send_keys("ship it #si")
    find("[data-category-suggestions] li", text: "#side-project").click
    assert_equal "ship it #side-project ", input.value
    assert_equal "new_task_form", evaluate_script("document.activeElement.form && document.activeElement.form.id")
  end

  test "Escape closes the suggestions and keeps typing in the box" do
    @input.send_keys("thing #w")
    assert_selector "[data-category-suggestions]", visible: true
    @input.send_keys(:escape)
    assert_no_selector "[data-category-suggestions]", visible: true
    assert_equal "new_task_form", evaluate_script("document.activeElement.form && document.activeElement.form.id")
  end

  test "Tab without a #tag moves on as normal" do
    @input.send_keys("plain task")
    assert_no_selector "[data-category-suggestions]", visible: true
    @input.send_keys(:tab)
    assert_equal "ADD", evaluate_script("document.activeElement.value")
  end

  test "no suggestions for a tag that matches nothing" do
    @input.send_keys("thing #zzz")
    assert_no_selector "[data-category-suggestions]", visible: true
  end
end
