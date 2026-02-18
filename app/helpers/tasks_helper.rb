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

  def darken_color(hex)
    hex = hex&.gsub("#", "") || "e5e7eb"
    r, g, b = hex.scan(/../).map { |c| c.to_i(16) / 255.0 }

    max = [ r, g, b ].max
    min = [ r, g, b ].min
    delta = max - min

    h = if delta == 0 then 0
    elsif max == r then 60 * (((g - b) / delta) % 6)
    elsif max == g then 60 * (((b - r) / delta) + 2)
    else 60 * (((r - g) / delta) + 4)
    end

    s = max == 0 ? 0 : delta / max
    l = 0.25 # target lightness for a "900" shade

    c = (1 - (2 * l - 1).abs) * s
    x = c * (1 - ((h / 60.0) % 2 - 1).abs)
    m = l - c / 2.0

    r1, g1, b1 = case (h / 60).to_i
    when 0 then [ c, x, 0 ]
    when 1 then [ x, c, 0 ]
    when 2 then [ 0, c, x ]
    when 3 then [ 0, x, c ]
    when 4 then [ x, 0, c ]
    else [ c, 0, x ]
    end

    "#%02x%02x%02x" % [ ((r1 + m) * 255).round, ((g1 + m) * 255).round, ((b1 + m) * 255).round ]
  end
end
