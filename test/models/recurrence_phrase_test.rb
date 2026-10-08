require "test_helper"

class RecurrencePhraseTest < ActiveSupport::TestCase
  TODAY = Date.new(2026, 10, 8) # a Thursday

  def parse(text) = RecurrencePhrase.extract(text, today: TODAY)

  def assert_rule(text, name, type, day, month = nil)
    remaining, rule = parse(text)
    assert_equal [ name, type, day, month ], [ remaining, rule&.type, rule&.day, rule&.month ], text
  end

  test "daily" do
    assert_rule "Water plants every day", "Water plants", "daily", nil
    assert_rule "Water plants daily", "Water plants", "daily", nil
  end

  test "weekly on a named day, full or short" do
    assert_rule "Get milk every monday", "Get milk", "weekly", 1
    assert_rule "Get milk every Mon", "Get milk", "weekly", 1
    assert_rule "Gym every Thursdays", "Gym", "weekly", 4
    assert_rule "Bins every week", "Bins", "weekly", TODAY.wday
    assert_rule "Report weekly", "Report", "weekly", TODAY.wday
  end

  test "monthly" do
    assert_rule "Pay rent every month on the 1st", "Pay rent", "monthly", 1
    assert_rule "Pay rent every 1st", "Pay rent", "monthly", 1
    assert_rule "Invoices every 31st of the month", "Invoices", "monthly", 31
    assert_rule "Budget every month", "Budget", "monthly", TODAY.day
    assert_rule "Budget monthly", "Budget", "monthly", TODAY.day
  end

  test "yearly" do
    assert_rule "Mum's birthday every March 15", "Mum's birthday", "yearly", 15, 3
    assert_rule "Mum's birthday every 15th March", "Mum's birthday", "yearly", 15, 3
    assert_rule "Mum's birthday every 15 of mar", "Mum's birthday", "yearly", 15, 3
    assert_rule "Leap day every year on Feb 29", "Leap day", "yearly", 29, 2
    assert_rule "Insurance annually", "Insurance", "yearly", TODAY.day, TODAY.month
  end

  def assert_interval(text, name, type, day, interval)
    remaining, rule = parse(text)
    assert_equal [ name, type, day, interval ], [ remaining, rule&.type, rule&.day, rule&.interval ], text
  end

  test "every other day, every weekday, every other week (as in TeuxDeux)" do
    assert_interval "Gym every other day", "Gym", "daily", nil, 2
    assert_interval "Stand-up every weekday", "Stand-up", "weekdays", nil, 1
    assert_interval "Stand-up on weekdays", "Stand-up", "weekdays", nil, 1
    assert_interval "Bins every other week", "Bins", "weekly", TODAY.wday, 2
    assert_interval "Bins fortnightly", "Bins", "weekly", TODAY.wday, 2
    assert_interval "Football every other Saturday", "Football", "weekly", 6, 2
  end

  test "only a phrase at the end counts" do
    assert_nil parse("Every Day Counts journal")
    assert_nil parse("Read every day this week")
  end

  test "impossible dates and bare phrases are left alone" do
    assert_nil parse("Party every February 30")
    assert_nil parse("Thing every 32nd")
    assert_nil parse("every monday")
  end
end
