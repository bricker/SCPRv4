class ContentAlarm < ActiveRecord::Base
  self.table_name = "contentbase_contentalarm"
  logs_as_task
  
  #----------
  # Scopes
  default_scope where("content_type is not null")
  scope :pending, -> { where("fire_at <= ?", Time.now).order("fire_at") }
  
  #----------
  # Association
  map_content_type_for_django
  belongs_to :content, polymorphic: true
  
  #----------
  # Validation
  validates_presence_of :fire_at
  
  #----------
  # Callbacks
  
  #---------------------
  
  def self.fire_pending
    self.pending.each do |alarm|
      alarm.fire
    end
  end

  #---------------------
  
  def fire
    if can_fire?
      ContentAlarm.log "Firing ContentAlarm ##{self.id} for #{self.content.simple_title}"
      if self.content.update_attributes(status: ContentBase::STATUS_LIVE)
        ContentAlarm.log "Published #{self.content.simple_title}. Removing this alarm."
        self.destroy
      else
        ContentAlarm.log "Couldn't save #{self.content.simple_title}. Will be tried again."
        false
      end
    else
      ContentAlarm.log "Can't fire ContentAlarm ##{self.id} for #{self.content.simple_title}"
      false
    end
  end
  
  #---------------------
  
  def pending?
    self.fire_at <= Time.now
  end

  #---------------------

  def can_fire?
    pending? and self.content.pending?
  end
end
