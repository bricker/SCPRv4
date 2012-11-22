class Category < ActiveRecord::Base
  include Concern::Validations::SlugValidation
  
  self.table_name = 'contentbase_category'
  ROUTE_KEY       = "category"
  has_secretary
  
  #-------------------
  # Scopes
  
  #-------------------
  # Associations
  belongs_to :comment_bucket, class_name: "FeaturedCommentBucket"
  
  #-------------------
  # Validations
  validates :title, presence: true
  
  #-------------------
  # Callbacks
  
  #-------------------
  # Administration
  administrate do
    define_list do
      list_per_page :all
      
      column :title
      column :slug
      column :is_news
      column :comment_bucket
    end
  end
  
  #-------------------
  # Sphinx
  acts_as_searchable
  
  define_index do
    indexes title
  end
  
  #----------

  def content(page=1,per_page=10,without_obj=nil)
    ts_max_matches = 1000 # Thinking Sphinx config 'max_matches', throws an error if the offset (from pagination) is higher than this number
    
    if page.to_i*per_page.to_i > ts_max_matches
      return []
    end
    
    args = {
      :page     => page,
      :per_page => per_page,
      :with     => { category: self.id }
    }
    
    if without_obj && without_obj.respond_to?("obj_key")
      args[:without] = { obj_key: without_obj.obj_key.to_crc32 }
    end
    
    ContentBase.search(args)
  end
  
  #----------
  
  def route_hash
    return {} if !self.persisted?
    { category: self.persisted_record.slug }
  end

  #----------
  
  def feature_candidates(args={})
    # lower decay decays more slowly. eg. rate of -0.01 will have a lower score after 3 days than -0.05
    
    candidates = []

    # -- first look for featured comments -- #

    featured = self.comment_bucket.comments.published

    if featured.any?
      # Initial score:  20
      # Decay rate:     0.05
      candidates << {
        :content  => featured.first,
        :score    => 20 * Math.exp( -0.04 * ((Time.now - featured.first.published_at) / 3600) ),
        :metric   => :comment
      }
    end


    # -- then try to feature videos since they are less common --#
    
    video = ContentBase.search({
      :classes     => [VideoShell],
      :limit       => 1,
      :with        => { category: self.id },
      :without_any => { obj_key: args[:exclude] ? args[:exclude].collect {|c| c.obj_key.to_crc32 } : [] }
    })
    
    if video.present?
      # Initial score: 15
      # Decay rate: 0.05
      video = video.first
      candidates << {
        :content  => video,
        :score    => (15 * Math.exp( -0.05 * ((Time.now - video.published_at) / 3600) ) ),
        :metric   => :video
      }
    end
    
    
    # -- now try slideshows -- #

    slideshow = ContentBase.search({
      :limit       => 1,
      :with        => { category: self.id, is_slideshow: true },
      :without_any => { obj_key: args[:exclude] ? args[:exclude].collect {|c| c.obj_key.to_crc32 } : [] }
    })

    if slideshow.any?
      # Initial score:  5 + number of slides
      # Decay rate:     0.01
      slideshow = slideshow.first

      candidates << {
        :content  => slideshow,
        :score    => (5 + slideshow.assets.size) * Math.exp( -0.01 * ((Time.now - slideshow.published_at) / 3600) ),
        :metric   => :slideshow
      }
    end

    # -- segment in the last two days? -- #

    segments = ContentBase.search({
      :classes     => [ShowSegment],
      :limit       => 1,
      :with        => { :category => self.id },
      :without_any => { obj_key: args[:exclude] ? args[:exclude].collect {|c| c.obj_key.to_crc32 } : [] }
    })

    if segments.any?
      # Initial score:  10
      # Decay rate:     0.02
      seg = segments.first

      candidates << {
        :content  => seg,
        :score    => 10 * Math.exp(-0.02 * ((Time.now - seg.published_at) / 3600) ),
        :metric   => :segment
      }
    end

    if candidates.any?
      return candidates.sort_by! {|c| -c[:score] }
    else
      return nil
    end
  end
end
