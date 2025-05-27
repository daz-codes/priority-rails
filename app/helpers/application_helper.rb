module ApplicationHelper
  def logo(size = :medium, link: true)
    size_class = case size
                 when :small  then "small"
                 when :large  then "big"
                 else              "medium"
                 end

    logo_content = safe_join([
      "PR".html_safe,
      content_tag(:span, "!", class: "blue-text"),
      "OR".html_safe,
      content_tag(:span, "!", class: "green-text"),
      "TY".html_safe,
      content_tag(:span, "!", class: "red-text")
    ])

    content_tag(:h1, class: "logo #{size_class}") do
      if link
        link_to("/", title: "PR!OR!TY!", class: "text-center") do
          logo_content
        end
      else
        content_tag(:span, logo_content, class: "text-center")
      end
    end
  end

end
