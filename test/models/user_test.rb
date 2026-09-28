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
end
