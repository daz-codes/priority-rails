require "application_system_test_case"

# Lists catch up when the app comes back from the background (lib/auto_refresh.js). Being "away"
# is simulated by stubbing the page's visibility state and clock.
class AutoRefreshTest < ApplicationSystemTestCase
  setup do
    @list = lists(:one)
    @list.tasks.destroy_all
    @list.tasks.create!(description: "Existing task")
    sign_in_as users(:one)
    visit list_url(@list)
  end

  def go_away_for(seconds)
    execute_script(<<~JS, (seconds.to_i * 1000))
      if (!window.__realNow) { window.__realNow = Date.now; window.__offset = 0 }
      Date.now = () => window.__realNow() + window.__offset
      Object.defineProperty(document, "visibilityState", { configurable: true, get: () => window.__visibility })
      window.__visibility = "hidden"
      document.dispatchEvent(new Event("visibilitychange"))
      window.__offset += arguments[0]
      window.__samePage = true
    JS
  end

  def come_back
    execute_script('window.__visibility = "visible"; document.dispatchEvent(new Event("visibilitychange"))')
  end

  test "coming back after a while brings in changes, without a full reload" do
    go_away_for(5.minutes)
    @list.tasks.create!(description: "Added while away")
    come_back
    assert_selector "#tasks li", text: "Added while away"
    assert evaluate_script("window.__samePage"), "expected a morph refresh, not a full page load"
  end

  test "a quick app switch doesn't refresh" do
    go_away_for(10.seconds)
    @list.tasks.create!(description: "Not yet")
    come_back
    sleep 1
    assert_no_selector "#tasks li", text: "Not yet"
  end

  test "settings pages are never refreshed" do
    visit edit_list_url(@list)
    find("input[name='list[name]']").fill_in(with: "Half typed")
    go_away_for(5.minutes)
    come_back
    sleep 1
    assert_equal "Half typed", find("input[name='list[name]']").value
  end
end
