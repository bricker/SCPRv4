class PressRelease < ActiveRecord::Base
  outpost_model
  has_secretary

  include Concern::Validations::SlugValidation
  include Concern::Callbacks::SphinxIndexCallback

  self.public_route_key = "press_release"

  #-------------
  # Scopes

  #-------------
  # Associations

  #-------------
  # Validation
  validates :short_title, presence: true
  validates :slug, uniqueness: true

  #-------------
  # Callbacks
  before_validation :generate_slug, if: -> { self.slug.blank? }

  # Since this object doesn't have a #headline, just do this manually.
  # Could merge it in with GenerateSlugCallback eventually.
  def generate_slug
    if self.short_title.present?
      self.slug = self.short_title.parameterize[0...50].sub(/-+\z/, "")
    end
  end

  #--------------

  def route_hash
    return {} if !self.persisted?
    { slug: self.slug }
  end
end
