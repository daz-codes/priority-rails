require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1000, 900 ]

  # Signs in with fetch rather than submitting the login form: a form login makes Chrome offer to
  # save the password, and that prompt can swallow keyboard input in the next steps
  def sign_in_as(user, password: "password")
    visit login_url
    execute_script(<<~JS, user.email_address, password)
      const body = new FormData()
      body.append("email_address", arguments[0])
      body.append("password", arguments[1])
      const token = document.querySelector("meta[name=csrf-token]")
      if (token) body.append("authenticity_token", token.content)
      window.__signedIn = fetch("/session", { method: "POST", body, credentials: "same-origin" }).then(r => r.ok)
    JS
    assert evaluate_async_script("window.__signedIn.then(arguments[0])"), "sign in failed"
  end

  def resize_to(width, height)
    page.driver.browser.manage.window.resize_to(width, height)
  end

  def task_row(text)
    find("#tasks li[id^='task_']", text: text)
  end

  # Fails on uncaught JS errors. Ignores favicon noise and a known Lexxy error when a row holding a
  # note editor is moved.
  def assert_no_js_errors
    errors = page.driver.browser.logs.get(:browser).map(&:message)
      .reject { |m| m.include?("icon") || m.include?("reading 'editor'") }
      .select { |m| m.include?("Uncaught") || m.include?("Error") }
    assert_empty errors
  end
end
