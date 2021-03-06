class Related < ActiveRecord::Base
  self.table_name = 'media_related'
  self.versioned_attributes = ["related_id", "related_type", "position"]

  # FIXME: Remove reference to ContentBase.
  # See HomepageContent for explanation.
  belongs_to :content,
    -> { where(status: ContentBase::STATUS_LIVE) },
    :polymorphic => true

  # Since we only build related content through the OWNER (i.e. incoming
  # references can't be managed through their article), we want to touch
  # the related article on save, but it's not necessary to touch the
  # owner article.
  belongs_to :related,
    -> { where(status: ContentBase::STATUS_LIVE) },
    :polymorphic    => true,
    :touch          => true


  def simple_json
    {
      "id"       => self.related.try(:obj_key), # TODO Store this in join table
      "position" => self.position.to_i
    }
  end
end
