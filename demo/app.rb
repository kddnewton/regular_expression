# frozen_string_literal: true

require "json"
require "regular_expression"
require "sinatra/base"

class App < Sinatra::Base
  get "/" do
    erb :index
  end

  post "/" do
    content_type :json

    body = request.body.read
    return status(400) if body.empty?

    data = JSON.parse(body)
    return status(400) if !valid?(data, "pattern") || !valid?(data, "value")

    pattern = RegularExpression::Pattern.new(data["pattern"])
    { match: !pattern.match?(data["value"]).nil? }.to_json
  end

  private

  def valid?(data, key)
    !data[key].nil? && !data[key].strip.empty?
  end
end
