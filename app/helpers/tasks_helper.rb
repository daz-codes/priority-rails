module TasksHelper
  # Snoozed tasks wake at the start of the day in the user's time zone, so "3 days" on Monday
  # means Thursday morning rather than Thursday at whatever time the page was opened
  def snooze_until(duration)
    (Date.current + duration).beginning_of_day
  end

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

  # The pencil swipe through a completed task's name (see .task-struck in bold.css), in its category's
  # colour or the tick's green. The pastel colour is mixed halfway towards its darker shade so the line
  # shows up on the tinted cards. Built here because an SVG data URI can't read a CSS variable
  def strike_line_style(task)
    color = ERB::Util.url_encode(task.category ? mix_colors(task.category.color, darken_color(task.category.color, lightness: 0.45)) : "#22b14c")
    svg = "%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 100 20' preserveAspectRatio='none'%3E%3Cdefs%3E%3ClinearGradient id='f' x1='0' x2='1'%3E" \
          "%3Cstop offset='0' stop-color='#{color}' stop-opacity='.7'/%3E%3Cstop offset='.7' stop-color='#{color}' stop-opacity='.65'/%3E" \
          "%3Cstop offset='1' stop-color='#{color}' stop-opacity='0'/%3E%3C/linearGradient%3E%3C/defs%3E" \
          "%3Cpath d='M1 13.6 Q50 8.7 99 6.6' fill='none' stroke='url%28%23f%29' stroke-width='3' stroke-linecap='round' vector-effect='non-scaling-stroke'/%3E%3C/svg%3E"
    "--strike-line: url(\"data:image/svg+xml;utf8,#{svg}\")"
  end

  # The colour halfway between two hex colours
  def mix_colors(a, b)
    channels = [ a, b ].map { |hex| hex.delete("#").scan(/../).map { |c| c.to_i(16) } }
    "#%02x%02x%02x" % channels.transpose.map { |x, y| ((x + y) / 2.0).round }
  end

  # Same hue, at the given lightness (0.25 is a "900" shade, for text on the pastel colour)
  def darken_color(hex, lightness: 0.25)
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
    l = lightness

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
