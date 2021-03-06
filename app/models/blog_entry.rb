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
  include Concern::Associations::IssueAssociation
  include Concern::Associations::FeatureAssociation
  include Concern::Associations::CategoryAssociation
  include Concern::Associations::HomepageContentAssociation
  include Concern::Associations::FeaturedCommentAssociation
  include Concern::Associations::QuoteAssociation
  include Concern::Associations::MissedItContentAssociation
  include Concern::Associations::EditionsAssociation
  include Concern::Associations::VerticalArticleAssociation
  include Concern::Validations::ContentValidation
  include Concern::Callbacks::SetPublishedAtCallback
  include Concern::Callbacks::GenerateShortHeadlineCallback
  include Concern::Callbacks::GenerateTeaserCallback
  include Concern::Callbacks::GenerateSlugCallback
  include Concern::Callbacks::CacheExpirationCallback
  include Concern::Callbacks::RedisPublishCallback
  include Concern::Callbacks::SphinxIndexCallback
  include Concern::Callbacks::HomepageCachingCallback
  include Concern::Callbacks::TouchCallback
  include Concern::Methods::ArticleStatuses
  include Concern::Methods::CommentMethods
  include Concern::Methods::AssetDisplayMethods

  self.disqus_identifier_base = "blogs/entry"
  self.public_route_key = "blog_entry"


  belongs_to :blog

  validates_presence_of :blog, if: :should_validate?


  def needs_validation?
    self.pending? || self.published?
  end


  # Need to work around multi-american until we can figure
  # out how to merge those comments in with kpcc
  def disqus_identifier
    if dsq_thread_id.present? && wp_id.present?
      "#{wp_id} http://multiamerican.scpr.org/?p=#{wp_id}"
    else
      super
    end
  end


  def disqus_shortname
    if dsq_thread_id.present? && wp_id.present?
      'scprmultiamerican'
    else
      super
    end
  end


  # Blog Entries don't need the "KPCC" credit,
  # so override the default +byline_extras+
  # behavior to return empty array
  def byline_extras
    []
  end


  def previous
    self.class.published
      .where(
        "published_at < ? and blog_id = ?", self.published_at, self.blog_id
      ).first
  end


  def next
    self.class.published
      .where(
        "published_at > ? and blog_id = ?", self.published_at, self.blog_id
      ).first
  end


  # This was made for the blog list pages - showing the full body
  # was too long, but just the teaser was too short.
  #
  # It should probably be in a presenter.
  def extended_teaser(*args)
    target      = args[0] || 800
    more_text   = args[1] || "Read More..."
    break_class = "story-break"

    content         = Nokogiri::HTML::DocumentFragment.parse(self.body)
    extended_teaser = Nokogiri::HTML::DocumentFragment.parse(nil)

    content.children.each do |child|
      if (child.attributes["class"].to_s == break_class) ||
      (extended_teaser.content.length >= target)
        break
      end

      extended_teaser.add_child child
    end

    extended_teaser.add_child(
      "<p><a href=\"#{self.public_path}\">#{more_text}</a></p>")

    return extended_teaser.to_html
  end


  def route_hash
    return {} if !self.persisted? || !self.persisted_record.published?
    {
      :blog           => self.persisted_record.blog.slug,
      :year           => self.persisted_record.published_at.year.to_s,
      :month          => "%02d" % self.persisted_record.published_at.month,
      :day            => "%02d" % self.persisted_record.published_at.day,
      :id             => self.persisted_record.id.to_s,
      :slug           => self.persisted_record.slug,
      :trailing_slash => true
    }
  end


  def to_article
    @to_article ||= Article.new({
      :original_object    => self,
      :id                 => self.obj_key,
      :title              => self.headline,
      :short_title        => self.short_headline,
      :public_datetime    => self.published_at,
      :teaser             => self.teaser,
      :body               => self.body,
      :category           => self.category,
      :assets             => self.assets,
      :audio              => self.audio.available,
      :attributions       => self.bylines,
      :byline             => self.byline,
      :edit_url           => self.admin_edit_url,
      :issues             => self.issues,
      :feature            => self.feature
    })
  end


  def to_abstract
    @to_abstract ||= Abstract.new({
      :original_object        => self,
      :headline               => self.short_headline,
      :summary                => self.teaser,
      :source                 => "KPCC",
      :url                    => self.public_url,
      :assets                 => self.assets,
      :audio                  => self.audio.available,
      :category               => self.category,
      :article_published_at   => self.published_at
    })
  end
end
