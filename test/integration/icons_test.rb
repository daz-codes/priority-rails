require "test_helper"

# Every icon the page and PWA manifest point to must exist in public/, or browsers
# silently fall back to their own default icon
class IconsTest < ActionDispatch::IntegrationTest
  def assert_public_file(url)
    path = Rails.public_path.join(URI(url).path.delete_prefix("/"))
    assert path.file?, "#{url} is referenced but #{path} doesn't exist"
  end

  test "page icons exist" do
    get login_url

    hrefs = css_select("link[rel=icon], link[rel=apple-touch-icon]").map { |link| link["href"] }
    assert_includes hrefs.map { |h| URI(h).path }, "/apple-touch-icon.png"
    hrefs.each { |href| assert_public_file(href) }
  end

  test "manifest icons exist, including a maskable one" do
    get pwa_manifest_url(format: :json)

    icons = JSON.parse(response.body).fetch("icons")
    icons.each { |icon| assert_public_file(icon["src"]) }
    assert icons.any? { |icon| icon["purpose"] == "maskable" }
  end
end
