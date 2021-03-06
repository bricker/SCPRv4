class HomepageContent < ActiveRecord::Base
  include Outpost::Aggregator::SimpleJson

  self.table_name = "layout_homepagecontent"
  self.versioned_attributes = ["content_type", "content_id", "position"]

  # FIXME: Can we figure out a way not to reference ContentBase here?
  # The problem is that "content" can be something that does use the
  # ContentBase statuses, like Event or PijQuery.
  # I suppose we could just switch back to always referencing ContentBase
  # _only_ for the "live" statuses. Not great but right now it's dangerous,
  # if someone changes one of those status numbers on another class then
  # that class won't show up on the Homepage, Missed it bucket, etc.
  belongs_to :content,
    -> { where(status: ContentBase::STATUS_LIVE) },
    :polymorphic    => true

  belongs_to :homepage
end
