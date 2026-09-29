require "test_helper"

class SearchesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @list = lists(:one)
    sign_in_as users(:one)
  end

  test "finds tasks by description, case-insensitively" do
    task = @list.tasks.create!(description: "Buy Oat Milk")

    get search_url(q: "oat milk")

    assert_select "#" + ActionView::RecordIdentifier.dom_id(task, :result), text: /Buy Oat Milk/
  end

  test "finds tasks by note text" do
    task = @list.tasks.create!(description: "Groceries", note: "<p>remember the saffron</p>")

    get search_url(q: "saffron")

    assert_select "#" + ActionView::RecordIdentifier.dom_id(task, :result)
  end

  test "finds lists by name" do
    get search_url(q: @list.name)

    assert_select "a[href='#{list_path(@list)}']", text: @list.name
  end

  test "links completed tasks to the completed tab" do
    task = @list.tasks.create!(description: "Filed taxes", completed: true)

    get search_url(q: "taxes")

    assert_select "a[href='#{list_path(@list, list: 'completed', anchor: ActionView::RecordIdentifier.dom_id(task))}']"
  end

  test "never shows tasks from lists the user isn't on" do
    lists(:two).tasks.create!(description: "Secret plans")

    get search_url(q: "secret")

    assert_select "p", text: /No tasks match/
  end

  test "treats wildcards literally" do
    sale = @list.tasks.create!(description: "Use 50% off voucher")
    other = @list.tasks.create!(description: "Order 500 labels")

    get search_url(q: "50%")

    assert_select "#" + ActionView::RecordIdentifier.dom_id(sale, :result)
    assert_select "#" + ActionView::RecordIdentifier.dom_id(other, :result), count: 0
  end
end
