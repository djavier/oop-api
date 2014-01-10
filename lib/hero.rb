class Hero
  include DataMapper::Resource
  belongs_to :weapon
  belongs_to :job
  belongs_to :race
  belongs_to :clan
  property :id, Serial
  property :name, String, required: true
end