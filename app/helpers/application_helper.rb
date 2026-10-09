module ApplicationHelper
  ICON_VERSION = 4

  def logo(size = :medium, link: true)
    size_class = case size
    when :small  then "text-3xl"
    when :large  then "text-7xl sm:text-[128px]"
    else              "text-6xl"
    end

    logo_content = safe_join([
      "PR".html_safe,
      content_tag(:span, "!", class: "text-brand-blue"),
      "OR".html_safe,
      content_tag(:span, "!", class: "text-brand-green"),
      "TY".html_safe,
      content_tag(:span, "!", class: "text-brand-red")
    ])

    content_tag(:h1, class: "font-brand my-2.5 #{size_class}") do
      if link
        link_to("/", title: "PR!OR!TY!", class: "no-underline text-text-primary hover:text-text-primary visited:text-text-primary text-center") do
          logo_content
        end
      else
        content_tag(:span, logo_content, class: "text-center")
      end
    end
  end

  # Centered task modals (snooze, recurrence, actions), styled to match the priority menu
  def modal_classes
    "fixed left-1/2 top-1/2 -translate-x-1/2 -translate-y-1/2 w-[90vw] max-w-sm bg-surface-primary " \
      "rounded-(--card-radius) shadow-2xl z-50 overflow-hidden"
  end

  # Dims and softly blurs the page behind the priority menu and modals, so it's still recognisable
  def modal_backdrop_classes
    "fixed inset-0 bg-black/20 backdrop-blur-[3px] z-40"
  end

  def task_button_classes
    "bg-transparent border-0 text-text-muted cursor-pointer p-0.5 text-sm hover:text-text-secondary transition-all duration-100"
  end

  # Labelled, tap-sized version of the task action buttons, used in the expanded task panel
  def task_panel_button_classes
    "inline-flex items-center gap-2 px-4 py-2 rounded-(--card-radius) border-2 border-border-input bg-surface-primary text-xs font-black uppercase " \
      "tracking-wider text-text-secondary cursor-pointer hover:border-brand-blue hover:text-brand-blue transition-all duration-100"
  end

  # ── The bold style used across forms and settings, matching the priority menu ──

  # A card holding one settings section
  def panel_classes
    "bg-surface-secondary rounded-(--card-radius) p-5"
  end

  def panel_heading_classes
    "text-xl font-heading text-text-primary mt-0 mb-3"
  end

  # Thick pill text box (also used for selects)
  def field_classes
    "w-full min-w-0 px-4 py-2.5 rounded-(--card-radius) border-[3px] border-[var(--input-border-bold)] text-base font-semibold " \
      "focus:outline-none focus:border-brand-blue bg-input-bg"
  end

  def primary_button_classes
    "inline-flex items-center justify-center gap-2 shrink-0 px-5 py-2.5 rounded-(--card-radius) bg-brand-blue text-white text-sm font-black " \
      "uppercase tracking-wider cursor-pointer hover:brightness-110 transition-all duration-100 border-0 no-underline"
  end

  def secondary_button_classes
    "inline-flex items-center justify-center gap-2 shrink-0 px-5 py-2 rounded-(--card-radius) border-2 border-border-input bg-surface-primary " \
      "text-xs font-black uppercase tracking-wider text-text-secondary hover:border-brand-blue hover:text-brand-blue " \
      "transition-all duration-100 cursor-pointer no-underline"
  end

  # Small uppercase text button inside a row, like Resend or Make owner
  def row_action_classes
    "text-[11px] font-black uppercase tracking-wider text-text-tertiary hover:text-brand-blue cursor-pointer bg-transparent border-none p-1"
  end

  def badge_classes
    "text-[10px] px-2 py-0.5 rounded-full font-black uppercase tracking-wider"
  end

  def error_box_classes
    "text-sm font-semibold text-red-600 bg-red-50 dark:bg-red-950 dark:text-red-300 rounded-(--card-radius) px-4 py-2.5"
  end

  # Icon-only in the task row, icon plus label when `labelled` (the expanded panel)
  def task_action_content(icon, label, labelled:)
    safe_join([ tag.i(class: "fa-solid #{icon}"), (tag.span(label) if labelled) ].compact)
  end

  TAB_COLORS = {
    "sky"     => { active: "bg-sky-100 text-sky-700 border border-sky-300 dark:bg-sky-900 dark:text-sky-200 dark:border-sky-700",
                   hover: "hover:bg-sky-50 dark:hover:bg-sky-950" },
    "red"     => { active: "bg-red-100 text-red-700 border border-red-300 dark:bg-red-900 dark:text-red-200 dark:border-red-700",
                   hover: "hover:bg-red-50 dark:hover:bg-red-950" },
    "amber"   => { active: "bg-amber-100 text-amber-700 border border-amber-300 dark:bg-amber-900 dark:text-amber-200 dark:border-amber-700",
                   hover: "hover:bg-amber-50 dark:hover:bg-amber-950" },
    "emerald" => { active: "bg-emerald-100 text-emerald-700 border border-emerald-300 dark:bg-emerald-900 dark:text-emerald-200 dark:border-emerald-700",
                   hover: "hover:bg-emerald-50 dark:hover:bg-emerald-950" }
  }.freeze

  def filter_tab_classes(active:, color: "sky")
    base = "text-sm px-3 py-1.5 rounded-full no-underline inline-block transition-all duration-100 font-semibold"
    tab = TAB_COLORS[color]
    if active
      "#{base} #{tab[:active]}"
    else
      "#{base} text-text-secondary border border-transparent #{tab[:hover]} hover:text-text-primary"
    end
  end
end
