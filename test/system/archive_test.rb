require "application_system_test_case"

class ArchiveTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @list = lists(:one)
    @list.update!(name: "Packing")
    @list.tasks.destroy_all
    @list.tasks.create!(description: "Passport", completed: true)
    @user.lists.create!(name: "Groceries", owner: @user)
    sign_in_as @user
  end

  test "archive a list, find it under Archived Lists, and unarchive it" do
    visit edit_list_url(@list)
    accept_confirm { click_on "Archive list" }
    assert_no_current_path edit_list_path(@list)

    find("[data-menu-toggle]").click
    within("[data-menu-modal]") do
      assert_no_text "Packing"
      click_on "Archived Lists (1)"
    end
    within("#archived_list_#{@list.id}") { click_on "Unarchive" }

    assert_current_path list_path(@list)
    assert_no_selector "[data-archived-banner]"
  end

  test "duplicate a list from its settings" do
    visit edit_list_url(@list)
    find("input[name=name][aria-label='Name for the copy']").fill_in(with: "Packing for Rome")
    click_on "Duplicate"

    assert_selector "h1", text: "Packing for Rome"
    assert_selector "#tasks li", text: "Passport"
    assert_no_selector "#tasks li .task-struck", text: "Passport"
  end
end
