class Job
  include DataMapper::Resource
  has n, :clans
  property :id, Serial
  property :name, String, required: true
end