# Quick-add recurrence: a phrase at the end of a new task's text, such as "Get milk every monday",
# "Gym every other day", "Stand-up every weekday", "Pay rent every month on the 1st" or
# "Mum's birthday every March 15". Only the end of the text is
# read, so names that merely contain "every" are left alone.
class RecurrencePhrase
  Rule = Data.define(:type, :day, :month, :interval) do
    def initialize(type:, day: nil, month: nil, interval: 1) = super
  end

  WEEKDAYS = {
    "sunday" => 0, "sun" => 0, "monday" => 1, "mon" => 1, "tuesday" => 2, "tues" => 2, "tue" => 2,
    "wednesday" => 3, "wed" => 3, "thursday" => 4, "thurs" => 4, "thur" => 4, "thu" => 4,
    "friday" => 5, "fri" => 5, "saturday" => 6, "sat" => 6
  }.freeze
  MONTHS = Date::MONTHNAMES.compact.each.with_index(1).flat_map { |name, number| [ [ name.downcase, number ], [ name[0, 3].downcase, number ] ] }.to_h.freeze

  WEEKDAY = WEEKDAYS.keys.sort_by(&:length).reverse.join("|")
  MONTH = MONTHS.keys.sort_by(&:length).reverse.join("|")
  ORDINAL = '(\d{1,2})(?:st|nd|rd|th)?'

  # Each pattern must match the very end of the text, after a space
  PATTERNS = [
    [ /\s+(?:every\s+day|daily)\z/i, ->(_, _) { Rule.new(type: "daily") } ],
    [ /\s+every\s+other\s+day\z/i, ->(_, _) { Rule.new(type: "daily", interval: 2) } ],
    [ /\s+(?:every\s+weekday|on\s+weekdays)s?\z/i, ->(_, _) { Rule.new(type: "weekdays") } ],
    [ /\s+every\s+(#{WEEKDAY})s?\z/i, ->(m, _) { Rule.new(type: "weekly", day: WEEKDAYS[m[1].downcase]) } ],
    [ /\s+every\s+other\s+(#{WEEKDAY})\z/i, ->(m, _) { Rule.new(type: "weekly", day: WEEKDAYS[m[1].downcase], interval: 2) } ],
    [ /\s+(?:every\s+week|weekly)\z/i, ->(_, today) { Rule.new(type: "weekly", day: today.wday) } ],
    [ /\s+(?:every\s+other\s+week|fortnightly)\z/i, ->(_, today) { Rule.new(type: "weekly", day: today.wday, interval: 2) } ],
    [ /\s+every\s+month\s+on\s+the\s+#{ORDINAL}\z/i, ->(m, _) { monthly(m[1]) } ],
    [ /\s+every\s+#{ORDINAL}(?:\s+of\s+the\s+month)?\z/i, ->(m, _) { monthly(m[1]) } ],
    [ /\s+(?:every\s+month|monthly)\z/i, ->(_, today) { Rule.new(type: "monthly", day: today.day) } ],
    [ /\s+every\s+year\s+on\s+(#{MONTH})\s+#{ORDINAL}\z/i, ->(m, _) { yearly(m[1], m[2]) } ],
    [ /\s+every\s+(#{MONTH})\s+#{ORDINAL}\z/i, ->(m, _) { yearly(m[1], m[2]) } ],
    [ /\s+every\s+#{ORDINAL}\s+(?:of\s+)?(#{MONTH})\z/i, ->(m, _) { yearly(m[2], m[1]) } ],
    [ /\s+(?:every\s+year|yearly|annually)\z/i, ->(_, today) { Rule.new(type: "yearly", day: today.day, month: today.month) } ]
  ].freeze

  # Returns [text without the phrase, Rule], or nil if the text doesn't end with a recurrence
  def self.extract(text, today: Date.current)
    text = text.to_s.rstrip
    PATTERNS.each do |pattern, build|
      next unless (match = pattern.match(text))
      next unless (rule = build.call(match, today))

      return [ match.pre_match.rstrip, rule ]
    end
    nil
  end

  def self.monthly(day)
    day = day.to_i
    Rule.new(type: "monthly", day: day) if day.between?(1, 31)
  end

  def self.yearly(month_name, day)
    month = MONTHS[month_name.downcase]
    day = day.to_i
    Rule.new(type: "yearly", day: day, month: month) if Date.valid_date?(2024, month, day) # 2024 so 29 February counts
  end
  private_class_method :monthly, :yearly
end
