# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def test_get
    response = get("/")

    assert_equal(200, response.status)
  end

  def test_post_with_match
    response = post("/", { pattern: "ab?c", value: "ac" }.to_json, headers)

    assert_equal(200, response.status)
    assert_equal("application/json", response.headers["Content-Type"])
    assert(JSON.parse(response.body)["match"])
  end

  def test_post_without_match
    response = post("/", { pattern: "ab?c", value: "42" }.to_json, headers)

    assert_equal(200, response.status)
    assert_equal("application/json", response.headers["Content-Type"])
    refute(JSON.parse(response.body)["match"])
  end

  def test_post_with_bad_values
    response = post("/", { foo: "bar" }.to_json, headers)

    assert_equal(400, response.status)
  end

  def test_post_empty
    response = post("/", {}.to_json, headers)

    assert_equal(400, response.status)
  end

  private

  def app
    App.new
  end

  def headers
    { "Content-Type" => "application/json" }
  end
end
