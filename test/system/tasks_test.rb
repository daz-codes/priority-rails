require "application_system_test_case"

class TasksTest < ApplicationSystemTestCase
  setup do
    resize_to(1000, 900)
    @user = users(:one)
    @list = lists(:one)
    @list.tasks.destroy_all
    @milk = @list.tasks.create!(description: "Buy milk", category: categories(:one))
    @report = @list.tasks.create!(description: "Write report", category: categories(:two),
                                  note: "<p>see <a href='https://example.com'>the brief</a></p>")
    sign_in_as @user
    visit list_url(@list)
  end

  test "adding a task, with a hashtag category" do
    within("#new_task_form") do
      find("input[name='task[description]']").set("Book dentist #work")
      find("input[type=submit]").click
    end

    assert_selector "#tasks li", text: "Book dentist"
    assert_equal categories(:two), @list.tasks.find_by(description: "Book dentist").category
    assert_no_selector ".turbo-progress-bar", visible: true
    assert_no_js_errors
  end

  test "ticking and unticking a task" do
    task_row("Buy milk").find("input.task-checkbox").click
    assert_selector "li##{dom_id(@milk)} .task-struck"
    assert @milk.reload.completed?

    task_row("Buy milk").find("input.task-checkbox").click
    assert_no_selector "li##{dom_id(@milk)} .task-struck"
    assert_not @milk.reload.completed?
    assert_no_js_errors
  end

  test "snoozing until the start of a day" do
    task_row("Buy milk").find("button[title=Snooze]").click
    assert_selector "[data-snooze-modal]", visible: true
    find("[data-snooze-modal] button[title=Close]").click
    assert_no_selector "[data-snooze-modal]", visible: true

    task_row("Buy milk").find("button[title=Snooze]").click
    find("[data-snooze-modal] div.cursor-pointer", exact_text: "3 Days").click

    assert_no_selector "#tasks li", text: "Buy milk"
    assert_equal (Date.current + 3).beginning_of_day, @milk.reload.snoozed_until
    assert_no_js_errors
  end

  test "snoozing until a chosen date" do
    task_row("Buy milk").find("button[title=Snooze]").click
    snooze = find("[data-snooze-modal]", visible: true)
    assert snooze.find_button("Snooze", disabled: true), "nothing to snooze until yet"

    date = Date.current + 10
    snooze.find("input[type=date]").execute_script("this.value = arguments[0]; this.dispatchEvent(new Event('input', { bubbles: true }))", date.iso8601)
    snooze.click_on "Snooze"

    assert_no_selector "#tasks li", text: "Buy milk"
    assert_equal date.beginning_of_day, @milk.reload.snoozed_until
    assert_no_js_errors
  end

  test "setting a recurrence, and the modal showing the current rule" do
    task_row("Buy milk").find("button[title=Recurrence]").click
    modal = find("[data-recurrence-modal]", visible: true)
    assert_selector "[data-recurrence-modal]", text: "Not recurring"
    modal.find("div.cursor-pointer", text: "Yearly").click
    modal.find("div.cursor-pointer", exact_text: "March").click
    modal.find(".grid div", exact_text: "15").click

    assert_selector "#tasks li", text: /every year on march 15/i
    assert_equal [ "yearly", 15, 3 ], @milk.reload.slice(:recurrence_type, :recurrence_day, :recurrence_month).values

    # Reopening shows this task's rule, and highlights it while keeping the option's own styling
    task_row("Buy milk").find("button[title=Recurrence]").click
    assert_selector "[data-recurrence-modal]", text: "Every year on March 15"
    yearly = find("[data-recurrence-modal] div.cursor-pointer", text: "Yearly")
    assert_includes yearly[:class], "text-cyan-400"
    assert_includes yearly[:class], "rounded-lg"

    # ...and a different task's modal shows its own rule
    find("[data-recurrence-modal] button[title=Close]").click
    task_row("Write report").find("button[title=Recurrence]").click
    assert_selector "[data-recurrence-modal]", text: "Not recurring"
    assert_no_js_errors
  end

  test "weekdays recurrence from the modal, and skipping a recurring task from the panel" do
    task_row("Buy milk").find("button[title=Recurrence]").click
    find("[data-recurrence-modal] div.cursor-pointer", text: "Weekdays").click
    assert_selector "#tasks li", text: /every weekday/i
    assert_equal "weekdays", @milk.reload.recurrence_type

    click_on "Buy milk"
    within("[data-task-panel]") { click_on "Skip this time" }
    assert_selector "[data-toast]", text: "Skipped until"
    assert_no_selector "#tasks li", text: "Buy milk"
    assert_equal Date.current.next_weekday.beginning_of_day, @milk.reload.snoozed_until
    assert_no_js_errors
  end

  test "notes show read-only, open links in a new tab, and edit in the task panel" do
    note = "#note_#{@report.id}"
    assert_no_selector note, visible: true
    task_row("Write report").find("button[title='toggle notes']").click
    assert_selector note, visible: true, text: "the brief"
    assert_equal "_blank", find("#{note} a", text: "the brief")[:target]
    assert_no_selector "#{note} [contenteditable]"

    within(note) { click_on "Edit" }
    within("[data-task-panel]") { assert_selector "[contenteditable]" }
    assert_no_js_errors
  end

  test "an image uploaded in the note editor shows in the task's note" do
    click_on "Buy milk"
    within("[data-task-panel]") do
      find("lexxy-editor [contenteditable]").click
      find("button[name=upload]").click # the editor's "Upload file" button adds a hidden file input
      find("lexxy-editor input[type=file]", visible: :all).send_keys(file_fixture("photo.png").to_s)
      assert_selector "lexxy-editor img", wait: 15
      # The preview shows straight away; wait for the upload to finish and be added to the note
      page.document.synchronize(15) do
        evaluate_script("document.querySelector('[data-task-panel] lexxy-editor').value.includes('sgid')") || raise(Capybara::ExpectationNotMet, "upload not finished")
      end
      click_on "Save"
    end
    assert_no_selector "[data-task-panel]" # saved and closed

    assert_equal [ "photo.png" ], @milk.reload.note.body.attachables.map { |blob| blob.filename.to_s }
    task_row("Buy milk").find("button[title='toggle notes']").click
    image = find("#note_#{@milk.id} img")
    assert evaluate_script("arguments[0].complete && arguments[0].naturalWidth > 0", image), "the image should load"
    assert_no_js_errors
  end

  test "notes stay open through a live refresh" do
    task_row("Write report").find("button[title='toggle notes']").click
    execute_script("Turbo.session.refresh(location.href)")
    sleep 1
    assert_selector "#note_#{@report.id}", visible: true
  end

  test "changing a task's category recolours the row straight away" do
    row_color = -> { evaluate_script("getComputedStyle(document.getElementById('#{dom_id(@milk)}')).getPropertyValue('--card-color').trim()") }
    task_row("Buy milk").find("select[name='task[category_id]']").select("Work")
    assert_equal categories(:two).color, row_color.call
    sleep 1
    assert_equal categories(:two), @milk.reload.category
  end

  test "the task panel saves name, list and note together, and Enter saves" do
    other = @user.lists.create!(name: "Weekend", owner: @user)
    click_on "Buy milk"
    within("[data-task-panel]") do
      fill_in "task[description]", with: "Buy oat milk"
      select "Weekend", from: "List"
      click_on "Save"
    end
    assert_selector "[data-toast]", text: "Moved to Weekend"
    assert_no_selector "#tasks li", text: "Buy oat milk"
    assert_equal [ "Buy oat milk", other ], @milk.reload.slice(:description, :list).values
    sleep 1 # let the refresh that follows a move finish before opening another panel

    click_on "Write report"
    within("[data-task-panel]") do
      find("input[name='task[description]']").set("Write the report")
      find("input[name='task[description]']").send_keys(:enter)
    end
    assert_selector "#tasks li", text: "Write the report"
    assert_no_js_errors
  end

  test "the panel's snooze and recur buttons open the shared modals" do
    click_on "Buy milk"
    within("[data-task-panel]") { click_on "Snooze" }
    assert_selector "[data-snooze-modal]", visible: true
    find("[data-snooze-modal] button[title=Close]").click
    within("[data-task-panel]") { click_on "Recur" }
    assert_selector "[data-recurrence-modal]", visible: true
  end

  test "deleting shows an undo toast that restores the task" do
    task_row("Buy milk").find("button[title='Delete task']").click
    assert_selector "[data-toast]", text: "Deleted “Buy milk”"
    assert_no_selector "#tasks li", text: "Buy milk"
    within("[data-toast]") { click_on "Undo" }
    assert_selector "#tasks li", text: "Buy milk"
    assert_no_js_errors
  end

  test "on a phone the row hides its action buttons" do
    resize_to(390, 844)
    visit list_url(@list)
    assert_no_selector "#tasks li button[title='Delete task']", visible: true
    click_on "Buy milk"
    within("[data-task-panel]") { assert_button "Delete" }
  end

  test "drag to reorder, including within a category filter" do
    drag_last_to_top = <<~JS
      const list = document.getElementById("tasks")
      const sortable = list[Object.keys(list).find(key => key.startsWith("Sortable"))]
      list.prepend(list.lastElementChild)
      sortable.options.onEnd()
    JS
    # Selenium can't perform HTML5 drag and drop, so move the row and fire Sortable's onEnd
    execute_script(drag_last_to_top)
    sleep 1
    assert_equal [ "Write report", "Buy milk" ], @list.tasks.ordered.pluck(:description)

    # A1 B2 B3 A4: filtered to B, move B3 above B2; the A tasks stay where they were
    @list.tasks.destroy_all
    %w[A1 B2 B3 A4].each { |name| @list.tasks.create!(description: name, category: name.start_with?("A") ? categories(:one) : categories(:two)) }
    visit list_url(@list, category_ids: [ categories(:two).id ])
    assert_selector "#tasks li", count: 2
    execute_script(drag_last_to_top)
    sleep 1
    assert_equal %w[A1 B3 B2 A4], @list.tasks.ordered.pluck(:description)
  end

  private

  def dom_id(...) = ActionView::RecordIdentifier.dom_id(...)
end
