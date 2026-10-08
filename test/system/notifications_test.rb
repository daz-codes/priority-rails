require "application_system_test_case"

# The profile's notification settings. Actually receiving pushes needs a live browser push service,
# so delivery is covered by unit tests with the sending stubbed.
class NotificationsSettingsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    sign_in_as @user
    visit edit_account_url
  end

  test "offers to turn notifications on for this device" do
    assert_text "Off for this device."
    assert_button "Turn on notifications on this device"
    assert_no_button "Turn off on this device"
  end

  test "notification preferences save with the profile" do
    uncheck "user[notify_on_list_activity]"
    click_on "Save"
    assert_no_current_path edit_account_path
    assert_not @user.reload.notify_on_list_activity?
    assert @user.notify_on_list_invites?
  end

  test "the service worker is served" do
    visit "/service-worker.js"
    assert_text "showNotification"
  end
end
