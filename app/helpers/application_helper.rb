module ApplicationHelper
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

  def task_button_classes
    "bg-transparent border-0 text-text-muted cursor-pointer p-0.5 text-sm hover:text-text-secondary transition-all duration-100"
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
