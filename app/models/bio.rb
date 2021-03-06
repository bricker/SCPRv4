class Bio < ActiveRecord::Base
  self.table_name = 'bios_bio'
  outpost_model
  has_secretary

  include Concern::Validations::SlugValidation
  include Concern::Associations::RelatedLinksAssociation
  include Concern::Callbacks::SphinxIndexCallback

  self.public_route_key = "bio"

  #--------------
  # Scopes
  scope :visible, -> { where(is_public: true) }

  #--------------
  # Associations
  belongs_to :user, class_name: "AdminUser"
  has_many :bylines, class_name: "ContentByline",  foreign_key: :user_id

  # Just in case a bio is deleted, remove its vertical association.
  has_many :vertical_reporters, dependent: :destroy

  #--------------
  # Validation
  validates :slug, uniqueness: true
  validates :name, presence: true
  validates :last_name, presence: true

  #--------------
  # Callbacks
  before_validation :set_last_name, if: -> { self.last_name.blank? }
  after_commit :touch_categories


  class << self
    # Maps all records to an array of arrays, to be
    # passed into a Rails select helper
    def select_collection
      self.order("last_name").map { |bio| [bio.name, bio.id] }
    end
  end

  #----------

  def indexed_bylines(page=1, per_page=15)
    # Sphinx max_matches limits how much it can offset results, so for Bios with a lot
    # of pages of Bylines, we have to fallback to an actual SQL query if the offset is
    # too high. Run some Ruby methods on the byines to mimic SQL's order and conditions.
    if page.to_i > (SPHINX_MAX_MATCHES / per_page.to_i)
      bylines = self.bylines.includes(:content)

      Kaminari.paginate_array(bylines.select { |b| b.content.published? }
             .sort_by { |b| b.content.published_at }
             .reverse)
             .page(page).per(per_page)
    else
      ContentByline.search('',
        :order        => "published_at #{DESCENDING}",
        :per_page     => per_page,
        :page         => page,
        :with         => {
          :user_id => self.id,
          :status  => ContentBase::STATUS_LIVE
        }
      )
    end
  end

  #---------------------

  def headshot
    if self.asset_id?
      @headshot ||= AssetHost::Asset.find(self.asset_id)
    end
  end


  def first_name
    if self.name?
      self.name.split[0]
    end
  end


  def json
    { asset: self.headshot }
  end

  #---------------------

  def route_hash
    return {} if !self.persisted? || !self.persisted_record.is_public?
    { slug: self.persisted_record.slug }
  end


  private

  def set_last_name
    if self.name.present?
      self.last_name = self.name.split(" ").last
    end
  end

  def touch_categories
    self.categories.each(&:touch)
  end
end
