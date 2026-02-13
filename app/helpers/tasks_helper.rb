module TasksHelper
  def snooze_time(task)
    if task.snoozed_until > 100.years.from_now
      "forever"
    else
      "for #{time_ago_in_words(task.snoozed_until)}"
    end
  end

  def highlight_class(task_id, highlight_id)
    " animate-highlight" if highlight_id == task_id
  end
end
