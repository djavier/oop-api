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


describe "Create a clan" do 
	before do
		@clan = Clan.new(name:"Avengers", desc:"One not so close team!")
		post "/api/v1/clans", @clan.to_json
	end

	it "should create a clan and increase the count by one" do
		lambda { post "/api/v1/clans", @clan.to_json }.must_change Clan.all, :count, +1
	end

	it "check if the clan has been created accordingly" do
	    post_data = post "/api/v1/clans", @clan.to_json
	    resp = JSON.parse(post_data.body)
	    resp["name"].must_equal "Avengers"
	    resp["desc"].must_equal "One not so close team!"
  	end
end

describe "See all clans" do
	it "should respond OK for clans index call" do
		get "/api/v1/clans"
		last_response.status.must_equal 200
	end
end

describe "See a specific clan" do
	before do
		clan = Clan.new(name:"Avengers", desc:"One not so close team!");
		post "/api/v1/clans", clan.to_json
	end

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

describe "Edit a clan" do
	before do
		@clan = Clan.new(name:"Avengers", desc:"One not so close team!", mascot_id:1, mascot_name:"Catdog")
	end
	it "should respond OK and update a clan succesfully" do
		put_data = put "/api/v1/clans/1", @clan.to_json
		put_data.status.must_equal 200

		resp = JSON.parse(put_data.body);
		resp['mascot_name'].must_equal "Catdog"
		resp['desc'].must_equal "One not so close team!"
	end
end

describe "Add a hero to a clan" do
	before do
		clan = Clan.new(name:"Avengers", desc:"One not so close team!", mascot_id:1, mascot_name:"Catdog")
		post 'api/v1/clans', clan.to_json
		@hero = Hero.new(id:1)
	end

	it "should add the hero to the clan succesfully" do
		put_data = post "/api/v1/clans/1/heroes", @hero.to_json
		put_data.status.must_equal 201
	end

	it "should add only four heroes to a clan" do 
		heroes = []
		last_hero = nil
		(1..5).each do |i|
			h = Hero.new(name:i.to_s, weapon_id:1, job_id:1, race_id:1)
			data = post "/api/v1/heroes", h.to_json
			if (i < 5)
				last_hero=	post "/api/v1/clans/1/heroes", data.body
			end
		end

		# last_hero = Hero.new(id:5)
		put_data = post "/api/v1/clans/1/heroes", {id:7}.to_json
		put_data.status.must_equal 500

	end
end

