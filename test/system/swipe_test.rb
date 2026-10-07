require "application_system_test_case"

# Touch swipes on task rows (behaviors/swipe.js), driven with Chrome's real touch input
class SwipeTest < ApplicationSystemTestCase
  setup do
    resize_to(390, 844)
    page.driver.browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: true, maxTouchPoints: 1)
    @list = lists(:one)
    @list.tasks.destroy_all
    @milk = @list.tasks.create!(description: "Buy milk", category: categories(:one))
    @report = @list.tasks.create!(description: "Write report", category: categories(:two))
    sign_in_as users(:one)
    visit list_url(@list)
    assert_selector "#tasks li", count: 2
  end

  # Browser tests share one Chrome session; leaving touch emulation on breaks later tests
  teardown do
    page.driver.browser.execute_cdp("Emulation.setTouchEmulationEnabled", enabled: false)
  end

  # Swipes horizontally across the middle of the row's text by `fraction` of the row width
  # (negative = left), lifting the finger at the end unless `release: false`
  def swipe(text, fraction, release: true, start_on: ".task-title", vertical: 0)
    row = find("#tasks li[id^='task_']", text: text)
    box = evaluate_script("(() => { const r = arguments[0].getBoundingClientRect(); const t = arguments[0].querySelector(arguments[1]).getBoundingClientRect(); return [r.width, t.left + t.width / 2, t.top + t.height / 2] })()", row, start_on)
    width, x, y = box
    touch = ->(type, px, py) { page.driver.browser.execute_cdp("Input.dispatchTouchEvent", type: type, touchPoints: type == "touchEnd" ? [] : [ { x: px, y: py } ]) }

    touch.("touchStart", x, y)
    steps = 12
    (1..steps).each { |i| touch.("touchMove", x + width * fraction * i / steps, y + vertical * i / steps) }
    yield row if block_given?
    touch.("touchEnd", 0, 0) if release
  end

  test "swiping left all the way deletes, with undo" do
    swipe("Buy milk", -0.8)
    assert_selector "[data-toast]", text: "Deleted “Buy milk”"
    assert_no_selector "#tasks li", text: "Buy milk"
    assert_not Task.exists?(@milk.id)
    assert_no_selector ".swipe-layer"

    within("[data-toast]") { click_on "Undo" }
    assert_selector "#tasks li", text: "Buy milk"
  end

  test "swiping right all the way opens the snooze picker for that task" do
    swipe("Buy milk", 0.8)
    assert_selector "[data-snooze-modal]", visible: true
    find("[data-snooze-modal] div.cursor-pointer", exact_text: "Day").click
    assert_no_selector "#tasks li", text: "Buy milk"
    assert_equal Date.tomorrow.beginning_of_day, @milk.reload.snoozed_until
  end

  test "a short swipe shows the action but springs back without doing it" do
    swipe("Buy milk", -0.35, release: false) do
      assert_selector ".swipe-layer[data-direction=delete]:not(.armed)", text: "Delete"
    end
    page.driver.browser.execute_cdp("Input.dispatchTouchEvent", type: "touchEnd", touchPoints: [])
    sleep 0.4
    assert_no_selector ".swipe-layer"
    assert_equal "", find("#tasks li", text: "Buy milk")[:style].to_s.then { |s| s[/transform:[^;]*/].to_s }
    assert Task.exists?(@milk.id)
    assert_no_selector "[data-snooze-modal]", visible: true
  end

  test "the strip arms once the swipe passes the threshold" do
    swipe("Write report", 0.75, release: false) do
      assert_selector ".swipe-layer.armed[data-direction=snooze]", text: "Snooze"
    end
    page.driver.browser.execute_cdp("Input.dispatchTouchEvent", type: "touchEnd", touchPoints: [])
  end

  test "a vertical drag is a scroll, not a swipe" do
    swipe("Buy milk", 0.05, vertical: 150)
    sleep 0.3
    assert_no_selector ".swipe-layer"
    assert_no_selector "[data-snooze-modal]", visible: true
    assert Task.exists?(@milk.id)
  end

  test "swipes that start on the tick circle are ignored" do
    swipe("Buy milk", -0.8, start_on: "input.task-checkbox")
    sleep 0.5
    assert Task.exists?(@milk.id)
  end

  test "completed tasks can be swiped away but not snoozed" do
    @milk.update!(completed: true)
    visit list_url(@list)
    swipe("Buy milk", 0.8)
    sleep 0.4
    assert_no_selector "[data-snooze-modal]", visible: true

    swipe("Buy milk", -0.8)
    assert_no_selector "#tasks li", text: "Buy milk"
  end

  test "ending a swipe on the task name doesn't also open the task" do
    swipe("Buy milk", 0.3)
    sleep 0.5
    assert_no_selector "[data-task-panel]"
  end
end
