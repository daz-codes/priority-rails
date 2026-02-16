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

    content_tag(:h1, class: "font-brand my-2.5 text-left #{size_class}") do
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

  def filter_tab_classes(active:)
    base = "text-sm px-3 py-1.5 rounded-full no-underline inline-block transition-all duration-100 font-semibold"
    if active
      "#{base} bg-lime-200 text-lime-700 border border-lime-300"
    else
      "#{base} text-text-secondary border border-transparent hover:bg-surface-hover hover:text-text-primary"
    end
  end
end
