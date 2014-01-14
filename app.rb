ENV['RACK_ENV'] = 'test'
# encoding: UTF-8
require 'rubygems'
require 'sinatra'
require 'json'
require 'data_mapper'
require 'puma'
require "sinatra/namespace"
require "sinatra/base"
if development? || test?
  require "sinatra/reloader" 
  require 'debugger' 
end
require 'haml'

#requiring model classes
['hero','job', 'race','weapon', 'mascot', 'clan'].each do |file|
  require File.join(File.dirname(__FILE__), 'lib', "#{file}.rb")
end

#requiring helpers
require_relative 'helpers/json_helper.rb'

#setting helper
helpers JsonHelpers

configure :development, :test, :production do
  register ::Sinatra::Namespace
  set :protection, true
  set :protect_from_csrf, true
  set :server, :puma

  if production?
    # Live Postgres for Heroku (Production):
    DataMapper.setup(:default, ENV['HEROKU_POSTGRESQL_AMBER_URL'] || 'postgres://localhost/mydb')
  else
    # Allows local requests such as Postman (Chrome extension):
    set :protection, origin_whitelist: ["chrome-extension://fdmmgilgnpjigdojojpjoooidkmcomcm", "http://127.0.0.1"]

    db_directory =  "#{File.expand_path(File.dirname(__FILE__))}/db"
    Dir::mkdir(directory) unless File.exists?(db_directory)
    # Local SQlite Locally (Development):
    DataMapper.setup(:default, "sqlite://"+db_directory+"/db.sqlite3")
  end

end

DataMapper.finalize
DataMapper.auto_migrate!

# Example data.
Job.create(name: 'Paladin')
Race.create(name: 'Human')
Weapon.create(name: 'Mithril Hammer', desc: "The almighty Thor Hammer, gives +10 to all stats")
Weapon.create(name: 'Blade of Olympus', desc: "The powerful Zeus' sword, gives +20 to strength and +10 to shield")
Mascot.create(name:'Night Fury', desc:"Highly intelligent breed of dragon evolved for speed and stealth")
Clan.create(name:"The Wolsitozurs", desc:"Just Don't", mascot_id:1, mascot_name:"Wolsy")
Hero.create(name: 'Thor', weapon_id: 1, job_id: 1, race_id: 1, clan_id: 1 )
Hero.create(name: 'Perseus', weapon_id: 1, job_id: 1, race_id: 1, clan_id: 1 )




get '/' do
  haml :index
end

get '/readme' do
  redirect "https://github.com/PixelPerfectTree/order-of-the-pixel"
end

# Namespacing the API for version one.
namespace '/api/v1' do

before do
  content_type :json

  headers["X-CSRF-Token"] = session[:csrf] ||= SecureRandom.hex(32)
   # To allow Cross Domain XHR
  headers["Access-Control-Allow-Origin"] ||= request.env["HTTP_ORIGIN"] 
  headers['Access-Control-Allow-Headers'] = %w{Origin Accept Content-Type X-Requested-With X-CSRF-Token}.join(',')

  #Enable preflight request to allow http request for PUT and DELETE methods
  if request.request_method == 'OPTIONS'
    response.headers["Access-Control-Allow-Methods"] = "POST, PUT, DELETE"
    halt 200
  end
 
end
  
  get '/clans' do
    clans = Clan.all
    clans.to_json
  end

  get '/clans/:id' do
    clan = Clan.get(params[:id])
    if clan.nil?
      halt 404
    end
    clan.to_json
  end

   get '/clans/:id/heroes' do
    clan = Clan.get(params[:id])
    if clan.nil?
      halt 404
    end
    clan.heroes.to_json
  end

  post '/clans' do 
    data = parsed_body
    if data.nil? || data['name'].nil?
      halt 400
    end

    clan = Clan.new(name: data['name'], desc: data['desc'], mascot_id: data['mascot_id'], mascot_name: data['mascot_name'])

    halt 500 unless clan.save
    status 201
    clan.to_json
  end

  put '/clans/:id' do
    data = parsed_body

    clan ||= Clan.get(params[:id]) || halt(404)
    
    halt 400 if data['name'].nil?
    halt 500 unless clan.update(
      name: data['name'],
      desc: data['desc'],
      mascot_id: data['mascot_id'],
      mascot_name: data['mascot_name']
      )
    clan.to_json    
  end

  post '/clans/:id/heroes' do
    data  = parsed_body

    if data.nil? || data['id'].nil?
      halt 400
    end

    clan ||= Clan.get(params[:id]) || halt(404)
    hero ||= Hero.get(data['id']) || halt(404)
    if clan.heroes.length == 4
      body "Clan #{clan.name} is not longer looking for heroes."
      halt 500 
    end
    clan.heroes.push hero
    halt 500 unless clan.save

    status 201
    clan.to_json
  end

  delete '/clans/:id' do
    clan ||= Clan.get(params[:id]) || halt(404)
    halt 404 if clan.nil?

    if clan.heroes.any?
      clan.heroes = []
      clan.save
    end

    if clan.destroy
      "The clan has been removed from the order."
    else
      halt 500
    end

  end

  # Index
  get '/heroes' do
    heroes = Hero.all
    heroes.to_json
  end

  # Show
  get '/heroes/:id' do
    hero = Hero.get(params[:id])
    if hero.nil?
      halt 404
    end
    hero.to_json
  end

  # Create
  post '/heroes' do
    data = parsed_body

    if data.nil? || data['name'].nil?
      halt 400
    end

    if !data['clan_id'].nil?
      clan = Clan.get(data['clan_id'])
      if (clan.heroes.length == 4 )
        body "Clan #{clan.name} is not longer looking for heroes."
        halt 500
      end
    end

    hero = Hero.new(name: data['name'], weapon_id: data['weapon_id'], job_id: data['job_id'], race_id: data['race_id'], clan_id: data['clan_id'])

    halt 500 unless hero.save
    status 201
    hero.to_json
  end

  # Update
  put '/heroes/:id' do
    data = parsed_body
    hero ||= Hero.get(params[:id]) || halt(404)
    halt 500 unless hero.update(
      name: data['name'],
      weapon_id: data['weapon_id'],
      job_id: data['job_id'], 
      race_id: data['race_id']
    )
    hero.to_json
  end

  # Delete
  delete '/heroes/:id' do
    hero ||= Hero.get(params[:id]) || halt(404)
    halt 404 if hero.nil?

    if hero.destroy
      "Your hero with an id of #{hero.id} has died with honour."
    else
      halt 500
    end
  end

  # Weapon routes

  # Index
  get '/weapons' do
    weapons = Weapon.all
    weapons.to_json
  end

  # Show
  get '/weapons/:id' do
    weapon = Weapon.get(parsed_body[:id])
    if weapon.nil?
      halt 404
    end
    weapon.to_json
  end

  # Create
  post '/weapons' do
    data = parsed_body
    
    if data.nil? || data['name'].nil?
      halt 400
    end
    
    weapon = Weapon.new(name: data['name'],desc:  data['desc'])
    halt 500 unless weapon.save
    [201, {'Location' => "/weapon/#{weapon.id}"}, weapon.to_json]
  end

  # Update
  put '/weapons/:id' do
    data = parsed_body
    weapon ||= Weapon.get(params['id']) || halt(404)

    if data.nil? || data['name'].nil? || data['desc'].nil?
      halt 400
    end

    halt 500 unless weapon.update(
      name: data['name'],
      desc: data['desc']
    )
    weapon.to_json
  end

  # Delete
  delete '/weapons/:id' do
    weapon ||= Weapon.get(params[:id]) || halt(404)
    halt 404 if weapon.nil?

    if weapon.destroy
      "Your weapon with an id of #{weapon.id} has been reduced to ashes!."
    else
      status 500
      body "The weapon with an id of #{weapon.id} doesn't exist or is related to a hero and can't be deleted."
    end
  end

  # RACE routes
  # Index
  get '/races' do
    races = Race.all
    races.to_json
  end

  # Show
  get '/races/:id' do
    race = Race.get(params[:id])
    if race.nil?
      halt 404
    end
    race.to_json
  end

  # Create
  post '/races' do
    data = parsed_body

    if data.nil? || data['name'].nil?
      halt 400
    end

    race = Race.new(name: data['name'])

    halt 500 unless race.save
    [201, {'Location' => "/race/#{race.id}"}, race.to_json]
  end

  # Update
  put '/races/:id' do
    data = parsed_body
    race ||= Race.get(params[:id]) || halt(404)
    halt 500 unless race.update(
      name:    data['name'],
    )
    race.to_json
  end

  # Delete
  delete '/races/:id' do
    race ||= Race.get(params[:id]) || halt(404)
    halt 404 if race.nil?

    if race.destroy
      "The race with an id of #{race.id} is now extinct."
    else
      status 500
      body "The race with an id of #{race.id} doesn't exist or is related to a hero and can't be deleted."
    end
  end

  # JOB routes

  # Index
  get '/jobs' do
    jobs = Job.all
    jobs.to_json
  end

  # Show
  get '/jobs/:id' do
    job = Job.get(params[:id])
    if job.nil?
      halt 404
    end
    job.to_json
  end

  # Create
  post '/jobs' do
    
    data = parsed_body

    if data.nil? || data['name'].nil?
      halt 400
    end

    job = Job.new(name: data['name'])

    halt 500 unless job.save
    [201, {'Location' => "/job/#{job.id}"}, job.to_json]
  end

  # Show
  put '/jobs/:id' do
    data = parsed_body
    job ||= Job.get(params[:id]) || halt(404)
    halt 500 unless job.update(
      name:    data['name'],
    )
    job.to_json
  end

  # Delete
  delete '/jobs/:id' do
    job ||= Job.get(params[:id]) || halt(404)

    if job.destroy
      "Your job with an id of #{job.id} has been eliminated."
    else
      status 500
      body "The job with an id of #{job.id} doesn't exist or is related to a hero and can't be deleted."
    end
  end

end


