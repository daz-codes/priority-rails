{ "Home" => "#a5f3fc", "Work" => "#d9f99d", "Hobbies" => "#fef08a" }.each do |name, color|
  Category.find_or_create_by!(name: name).update!(color: color)
end
