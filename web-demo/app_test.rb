# frozen_string_literal: true

require "rack/test"
require_relative "app"

RSpec.configure do |config|
  config.include Rack::Test::Methods
  config.expect_with(:rspec) { |c| c.syntax = %i[expect should] }
end

describe App do
  let(:app) { App.new }
  let(:headers) { { "Content-Type" => "application/json" } }

  context "GET to /" do
    let(:response) { get "/" }

    it "returns HTTP status OK" do
      expect(response.status).to eq 200
    end
  end

  context "POST to / with a match" do
    let(:body) { { pattern: "ab?c", value: "ac" }.to_json }
    let(:response) { post "/", body, headers }

    it "returns HTTP status OK" do
      expect(response.status).to eq 200
    end

    it "returns application JSON" do
      expect(response.headers["Content-type"]).to eq("application/json")
    end

    it "returns a match" do
      expect(JSON.parse(response.body)).to eq({ "match" => true })
    end
  end

  context "POST to / without a match" do
    let(:body) { { pattern: "ab?c", value: "42" }.to_json }
    let(:response) { post "/", body, headers }

    it "returns HTTP status OK" do
      expect(response.status).to eq 200
    end

    it "returns application JSON" do
      expect(response.headers["Content-type"]).to eq("application/json")
    end

    it "does not return a match" do
      expect(JSON.parse(response.body)).to eq({ "match" => false })
    end
  end

  context "wrong POST to /" do
    let(:body) { { foo: "bar" }.to_json }
    let(:response) { post "/", body, headers }

    it "returns HTTP status Bad Request" do
      expect(response.status).to eq 400
    end
  end

  context "empty POST to /" do
    let(:response) { post "/", {}.to_json, headers }

    it "returns HTTP status Bad Request" do
      expect(response.status).to eq 400
    end
  end
end
