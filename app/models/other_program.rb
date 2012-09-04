class OtherProgram < ActiveRecord::Base
  self.table_name =  'programs_otherprogram'  

  # -------------------
  # Administration
  administrate do |admin|
    admin.define_list do |list|
      list.order = "title"
      list.per_page   = "all"
      
      list.column "title"
      list.column "produced_by"
      list.column "air_status"
    end
  end

  # -------------------
  # Associations
  has_many :schedules, :foreign_key => "other_program_id", :class_name => "Schedule"
  
  # -------------------
  # Scopes
  scope :active, where(:air_status => ['onair','online'])
  
  def display_segments
    false
  end
  
  def display_episodes
    false
  end
  
  #----------
  
  def to_param
    slug
  end
  
  #----------
  
  def remote_link_path
    "http://www.scpr.org#{link_path}"
  end
  
  def link_path
    Rails.application.routes.url_helpers.program_path(self,:trailing_slash => true)
  end
  
  #----------
  
  def cache
    view = ActionView::Base.new(ActionController::Base.view_paths, {})  

    class << view  
      include ApplicationHelper
    end
    
    if self.podcast_url?
      begin
        podcast = Feedzirra::Feed.fetch_and_parse self.podcast_url
      rescue
        podcast = nil
      end
      
      if podcast.present? && !podcast.is_a?(Fixnum)
        podcast_html = view.render :partial => "programs/cached/podcast_entry", :collection => podcast.entries.first(5), :as => :entry
        Rails.cache.write("ext_program:#{self.slug}:podcast", podcast_html)
      end
    end
    
    if self.rss_url?
      begin
        rss = Feedzirra::Feed.fetch_and_parse self.rss_url
      rescue
        rss = nil
      end
      
      if rss.present? && !rss.is_a?(Fixnum)
        Rails.cache.write(
          "ext_program:#{self.slug}:rss", 
           view.render(:partial => "programs/cached/podcast_entry", :collection => rss.entries.first(5), :as => :entry)
        )
      end
    end # rss_url?
    return podcast.present? || rss.present?
  end
end
