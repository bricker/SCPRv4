class BlogEntry < ActiveRecord::Base
  self.table_name = "blogs_entry"
  outpost_model
  has_secretary

  include Concern::Scopes::SinceScope
  include Concern::Scopes::PublishedScope
  include Concern::Associations::ContentAlarmAssociation
  include Concern::Associations::AudioAssociation
  include Concern::Associations::AssetAssociation
  include Concern::Associations::RelatedContentAssociation
  include Concern::Associations::RelatedLinksAssociation
  include Concern::Associations::BylinesAssociation
  include Concern::Associations::CategoryAssociation
  include Concern::Validations::ContentValidation
  include Concern::Callbacks::SetPublishedAtCallback
  include Concern::Callbacks::GenerateSlugCallback
  include Concern::Callbacks::CacheExpirationCallback
  include Concern::Callbacks::RedisPublishCallback
  include Concern::Callbacks::TouchCallback
  include Concern::Methods::StatusMethods
  include Concern::Methods::PublishingMethods
  include Concern::Methods::CommentMethods
  include Concern::Methods::HeadlineMethods
  include Concern::Methods::TeaserMethods
  include Concern::Methods::ContentJsonMethods
  
  ROUTE_KEY = "blog_entry"
  
  ASSET_SCHEMES = [
    ["Full Width (default)", ""],
    ["Float Right", "right"],
    ["Slideshow", "slideshow"],
    ["No Display", "hidden"]
  ]
  
  #------------------
  # Scopes
  
  #------------------
  # Association
  belongs_to :blog
  has_many :tagged, class_name: "TaggedContent", as: :content
  has_many :tags, through: :tagged, dependent: :destroy

  #------------------
  # Validation
  validates_presence_of :blog
  
  def needs_validation?
    self.pending? || self.published?
  end
  
  #------------------
  # Callbacks

  #------------------
  # Sphinx
  acts_as_searchable
  
  define_index do
    indexes headline
    indexes body
    indexes bylines.user.name, as: :bylines
    has blog.id, as: :blog
    has category.id, as: :category
    has category.is_news, as: :category_is_news
    has published_at
    has updated_at
    has status
    has blog.is_active, as: :findable, type: :boolean
    has "1", as: :is_source_kpcc, type: :boolean
    has "CRC32(CONCAT('blogs/entry:',#{BlogEntry.table_name}.id))", type: :integer, as: :obj_key
    has "(#{BlogEntry.table_name}.blog_asset_scheme <=> 'slideshow')", type: :boolean, as: :is_slideshow
    has "COUNT(DISTINCT #{Audio.table_name}.id) > 0", type: :boolean, as: :has_audio
    join audio
  end

  #-------------------
  # Need to work around multi-american until we can figure
  # out how to merge those comments in with kpcc
  def disqus_identifier
    if dsq_thread_id.present? && wp_id.present?
      "#{wp_id} http://multiamerican.scpr.org/?p=#{wp_id}"
    else
      super
    end
  end

  #-------------------
  
  def disqus_shortname
    if dsq_thread_id.present? && wp_id.present?
      'scprmultiamerican'
    else
      super
    end
  end

  #-------------------
  # Blog Entries don't need the "KPCC" credit,
  # so override the default +byline_extras+
  # behavior to return empty array
  def byline_extras
    []
  end
  
  #-------------------
  
  def previous
    self.class.published.where("published_at < ? and blog_id = ?", self.published_at, self.blog_id).first
  end

  #-------------------

  def next
    self.class.published.where("published_at > ? and blog_id = ?", self.published_at, self.blog_id).first
  end
  
  #-------------------
  
  def extended_teaser(*args)
    target      = args[0] || 800
    more_text   = args[1] || "Read More..."
    break_class = "story-break"
    
    content         = Nokogiri::HTML::DocumentFragment.parse(self.body)
    extended_teaser = Nokogiri::HTML::DocumentFragment.parse(nil)
    
    content.children.each do |child|
      break if (child.attributes["class"].to_s == break_class) || (extended_teaser.content.length >= target)
      extended_teaser.add_child child
    end
    
    extended_teaser.add_child "<p><a href=\"#{self.link_path}\">#{more_text}</a></p>"
    return extended_teaser.to_html
  end
  
  #-------------------

  def route_hash
    return {} if !self.persisted? || !self.persisted_record.published?
    {
      :blog           => self.persisted_record.blog.slug,
      :year           => self.persisted_record.published_at.year, 
      :month          => "%02d" % self.persisted_record.published_at.month,
      :day            => "%02d" % self.persisted_record.published_at.day,
      :id             => self.persisted_record.id,
      :slug           => self.persisted_record.slug,
      :trailing_slash => true
    }
  end
end
