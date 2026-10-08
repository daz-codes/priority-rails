require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "email must be unique regardless of case" do
    user = User.new(email_address: "ONE@example.com", password: "password")

    assert_not user.valid?
    assert_includes user.errors[:email_address], "has already been taken"
  end

  test "email must look like an email" do
    assert_not User.new(email_address: "nope", password: "password").valid?
  end

  test "password must be at least 8 characters" do
    assert_not User.new(email_address: "new@example.com", password: "short").valid?
    assert User.new(email_address: "new@example.com", password: "longenough").valid?
  end

  test "existing users can be updated without setting a password" do
    assert users(:one).update(name: "One")
  end

  test "browser time zones map to Rails names, preferring the matching city" do
    assert_equal "London", User.time_zone_from_browser("Europe/London")
    assert_equal "Eastern Time (US & Canada)", User.time_zone_from_browser("America/New_York")
    assert_equal "Tokyo", User.time_zone_from_browser("Asia/Tokyo")
  end

  test "browser zones without a Rails name are kept, and still valid" do
    assert_equal "America/Indiana/Knox", User.time_zone_from_browser("America/Indiana/Knox")
    assert users(:one).update(time_zone: "America/Indiana/Knox")
  end

  test "unknown browser zones are ignored" do
    assert_nil User.time_zone_from_browser("Mars/Olympus")
    assert_nil User.time_zone_from_browser(nil)
  end

  test "time zone can be left unset" do
    assert users(:one).update(time_zone: nil)
  end
end
