class Clan
	 include DataMapper::Resource
  has n, :heroes
  belongs_to :mascot, required: false
  property :id, Serial
  property :name, String, required: true
  property :desc, String, length: 255
  property :mascot_name, String, length: 40
end