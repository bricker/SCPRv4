class VideoShell < ContentBase
  include Model::Methods::StatusMethods
  include Model::Methods::PublishingMethods
  include Model::Validations::ContentValidation
  include Model::Validations::SlugValidation
  include Model::Validations::PublishedAtValidation
  include Model::Associations::ContentAlarmAssociation
  include Model::Associations::AssetAssociation
  include Model::Scopes::SinceScope


  self.table_name = "contentbase_videoshell"
  ROUTE_KEY       = "video"
  
  acts_as_content
  has_secretary
  
  def self.content_key
    "content/video"
  end
  
  # -------------------
  # Validations
  validates :slug, uniqueness: true
  
  
  # -------------------
  # Scopes
  
  
  # -------------------
  # Administration
  administrate do
    define_list do
      order = "published_at desc"
      column "headline"
      column "slug"
      column "bylines"
      column "status"
      column "published_at"
    end
  end


  # -------------------
    
  define_index do
    indexes headline
    indexes body
    has category.id, :as => :category
    has category.is_news, :as => :category_is_news
    has published_at
    has "CRC32(CONCAT('content/video:',contentbase_videoshell.id))", :type => :integer, :as => :obj_key
    has "1", :as => :is_source_kpcc, :type => :boolean
    has "0", :as => :is_slideshow, :type => :boolean
    has "0", :as => :has_audio, :type => :boolean
    where "status = #{STATUS_LIVE}"
  end
  
  #--------------------

  def route_hash
    return {} if !self.persisted? || !self.published?
    {
      :id             => self.persisted_record.id,
      :slug           => self.persisted_record.slug,
      :trailing_slash => true
    }
  end
end
