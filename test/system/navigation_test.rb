require "application_system_test_case"

class NavigationTest < ApplicationSystemTestCase
  setup do
    resize_to(1000, 900)
    @user = users(:one)
    @list = lists(:one)
    @list.tasks.destroy_all
    @milk = @list.tasks.create!(description: "Buy milk", category: categories(:one))
    @list.tasks.create!(description: "Write report", category: categories(:two))
    sign_in_as @user
  end

  test "the menu opens, filters lists and closes on an outside click" do
    @user.lists.create!(name: "Weekend jobs", owner: @user)
    visit list_url(@list)
    find("[data-menu-toggle]").click
    assert_selector "[data-menu-modal]", visible: true
    find("[data-menu-modal] input").fill_in(with: "weekend")
    assert_selector "[data-menu-list] li", visible: true, count: 1, text: "Weekend jobs"
    execute_script("document.body.dispatchEvent(new MouseEvent('click', { bubbles: true }))")
    assert_no_selector "[data-menu-modal]", visible: true
    assert_no_js_errors
  end

  test "keyboard shortcuts" do
    visit list_url(@list)
    find("main").click
    find("body").send_keys("p")
    assert_selector "[data-menu-modal]", visible: true
    find("body").send_keys(:escape)
    assert_no_selector "[data-menu-modal]", visible: true

    find("body").send_keys(:down)
    assert_selector "li.keyboard-selected", text: "Buy milk"
    find("body").send_keys(:enter)
    assert_selector "li##{ActionView::RecordIdentifier.dom_id(@milk)} .task-struck"

    find("body").send_keys("/")
    assert_equal "new_task_form", evaluate_script("document.activeElement.form && document.activeElement.form.id")
  end

  test "focus mode shows only numbered tasks, and Escape goes back" do
    visit list_url(@list)
    within("#list_actions") { click_on "Focus" }
    assert_selector ".focus-rank", text: "1"
    assert_no_selector "#list_actions"
    assert_no_selector "[data-menu-toggle]"
    find("body").send_keys(:escape)
    assert_selector "#list_actions"
  end

  test "completed years load when opened" do
    @list.tasks.create!(description: "Old taxes", completed_on: Time.zone.local(Date.current.year - 1, 4, 1, 12))
    visit list_url(@list, list: "completed")
    assert_no_text "Old taxes"
    find("summary", text: (Date.current.year - 1).to_s).click
    assert_text "Old taxes"
  end

  test "list settings save as you change them" do
    visit edit_list_url(@list)
    select "1 week", from: "list[completed_display]"
    sleep 1
    assert_equal "1_week", @list.reload.completed_display

    within("##{ActionView::RecordIdentifier.dom_id(categories(:one))}") { all("label span")[0].click }
    sleep 1
    assert_equal CategoriesController::COLORS.first, categories(:one).reload.color
    assert_no_js_errors
  end

  test "the theme toggle switches between light and dark" do
    visit edit_account_url
    dark = -> { evaluate_script("document.documentElement.classList.contains('dark')") }
    started_dark = dark.call
    click_on(started_dark ? "Switch to light mode" : "Switch to dark mode")
    assert_equal !started_dark, dark.call
    assert_button(started_dark ? "Switch to dark mode" : "Switch to light mode")
  end

  test "the time zone is detected from the browser when the account has none" do
    @user.update!(time_zone: nil)
    page.driver.browser.execute_cdp("Emulation.setTimezoneOverride", timezoneId: "America/New_York")

    visit list_url(@list)
    assert_selector "#tasks li", text: "Buy milk" # the page refreshes after saving the zone
    sleep 1
    assert_equal "Eastern Time (US & Canada)", @user.reload.time_zone

    # Once set, it isn't sent again, and a later change of device zone doesn't override it
    page.driver.browser.execute_cdp("Emulation.setTimezoneOverride", timezoneId: "Asia/Tokyo")
    visit list_url(@list)
    assert_no_selector "meta[name=detect-time-zone]", visible: :all
    assert_equal "Eastern Time (US & Canada)", @user.reload.time_zone
  ensure
    page.driver.browser.execute_cdp("Emulation.setTimezoneOverride", timezoneId: "")
  end

  test "categories reorder by dragging their handle in settings" do
    visit edit_list_url(@list)
    assert_selector "[data-category-list] .category-handle", count: 2
    # Selenium can't perform HTML5 drag and drop: move the row and fire Sortable's onEnd
    execute_script(<<~JS)
      const list = document.querySelector("[data-category-list]")
      const sortable = list[Object.keys(list).find(key => key.startsWith("Sortable"))]
      list.prepend(list.lastElementChild)
      sortable.options.onEnd()
    JS
    sleep 1
    assert_equal %w[Work Home], @list.reload.categories.pluck(:name)
  end
end
