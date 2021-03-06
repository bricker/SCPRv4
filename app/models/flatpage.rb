class Flatpage < ActiveRecord::Base
  self.table_name = "flatpages_flatpage"
  outpost_model
  has_secretary

  include Concern::Callbacks::SphinxIndexCallback

  self.public_route_key = 'root_slug'

  TEMPLATE_OPTIONS = [
    ["Normal (with sidebar)",   "inherit"],
    ["Full Width (no sidebar)", "full"],
    ["Crawford Family Forum",   "forum"],
    ["No Template",             "none"]
  ]

  # -------------------
  # Scopes
  scope :visible, -> { where(is_public: true) }

  # -------------------
  # Associations

  # -------------------
  # Validations
  validates :path,
    :presence => true,
    :uniqueness => true,
    :format => {
      :with    => %r{\A[^/].+[^/]\z},
      :message => "is an invalid format. " \
                  "The path should NOT start or end with a slash."
    }


  # -------------------
  # Callbacks

  # Downcase path so uniqueness validation works.
  before_validation :downcase_path
  def downcase_path
    if path.present?
      self.path = path.downcase
    end
  end

  # -------------------

  def route_hash
    return {} if !self.persisted? || !self.persisted_record.is_public?
    { path: self.persisted_record.path }
  end

  # -------------------

  def is_redirect?
    self.redirect_to.present?
  end
end
