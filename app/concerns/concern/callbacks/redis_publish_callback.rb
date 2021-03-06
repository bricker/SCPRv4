##
# RedisPublishCallback
#
# Sends message to Redis pub/sub
# Requires StatusBuilder methods.
module Concern
  module Callbacks
    module RedisPublishCallback
      extend ActiveSupport::Concern

      included do
        after_save :publish_to_redis
      end

      #---------------------------

      def publish_to_redis
        if self.publishing?
          Publisher.publish({
            :object     => self,
            :action     => "publish",
            :options    => {
              :status_change    => true,
              :old_status       => self.status_was
            }
          })

        elsif self.unpublishing?
          Publisher.publish({
            :object     => self,
            :action     => "unpublish",
            :options    => {
              :status_change    => true,
              :old_status       => self.status_was
            }
          })

        else
          if !self.status_was || !self.status_changed?
            Publisher.publish({
              :object     => self,
              :action     => "save",
              :options    => {
                :status_change => false
              }
            })
          else
            Publisher.publish({
              :object => self,
              :action => "save",
              :options => {
                :status_change => true,
                :old_status => self.status_was
              }
            })
          end
        end
      end
    end # CacheExpiration
  end # Callbacks
end # Concern
