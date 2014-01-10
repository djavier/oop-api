class Mascot
	 include DataMapper::Resource
  has n, :clans
  property :id, Serial
  property :name, String, required: true
  property :desc, String, length: 255
end