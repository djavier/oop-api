ENV['RACK_ENV'] = 'test'
gem "minitest"
require 'rack/test'
require 'minitest/autorun'
require_relative '../app.rb'
require_relative 'helpers.rb'
include Rack::Test::Methods

def app
  Sinatra::Application
end

describe "See all clans" do
	it "should respond OK for clans index call" do
		get "/api/v1/clans"
		last_response.status.must_equal 200
	end
end

describe "See a specific clan" do
	it "should respond OK for clan show call" do
		get "/api/v1/clans/1"
		last_response.status.must_equal 200
	end

	it "should respond 404 for non-existent clans" do
		get "/api/v1/clans/999"
		last_response.status.must_equal 404
	end
end

describe "See heroes from a specific clan" do
	it "should respond OK for clan show call" do
		get "/api/v1/clans/1/heroes"
		last_response.status.must_equal 200
	end

	it "should respond 404 for non-existent clans" do
		get "/api/v1/clans/999/heroes"
		last_response.status.must_equal 404
	end
end

describe "Create a clan" do 
	before do
		@clan = Clan.new(name:"Avengers")
	end

	it "should create a clan and increase the count by one" do 
		lambda { post "/api/v1/clans", @clan.to_json }.must_change Clan.all, :count, +1
	end


end

