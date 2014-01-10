class Clan
	 include DataMapper::Resource
  has n, :heroes
  belongs_to :mascot
  property :id, Serial
  property :name, String, required: true
  property :desc, String, length: 255
end