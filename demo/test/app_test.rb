# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  include Rack::Test::Methods

  def test_get
    response = get("/")

    assert_equal(200, response.status)
  end

  def test_post_with_match
    skip
    response = post("/", { pattern: "ab?c", value: "ac" }.to_json, headers)
    ui = UI::Match.new(graph: "<!-- Generated by graphviz")

    assert_equal(200, response.status)
    assert_include_match_ui(response.body, ui)
    assert_includes(response.body, ui.graph)
  end

  def test_post_without_match
    response = post("/", { pattern: "ab?c", value: "42" }.to_json, headers)

    assert_equal(200, response.status)
    assert_include_match_ui(response.body, UI::NO_MATCH)
  end

  def test_post_with_broken_pattern
    response = post("/", { pattern: "a(", value: "42" }.to_json, headers)

    assert_equal(200, response.status)
    assert_include_match_ui(response.body, UI::ERROR)
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

  def assert_include_match_ui(body, match)
    assert_includes(body, match.text)
    assert_includes(body, match.icon)
    assert_includes(body, match.color)
  end
end
