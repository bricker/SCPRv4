##
# AudioAssociation
#
# Association and callbacks for Audio
#
module Concern
  module Associations
    module AudioAssociation
      extend ActiveSupport::Concern

      included do
        has_many :audio,
          -> { order('position') },
          :as           => :content,
          :dependent    => :destroy

        if self.has_secretary?
          tracks_association :audio
        end

        accepts_nested_attributes_for :audio,
          :allow_destroy    => true,
          :reject_if        => :should_reject_audio?
      end


      private

      # If all of these attributes are blank, reject it,
      # because it means they weren't trying to attach
      # any audio.
      #
      # Otherwise, the person was trying to do something
      # and we should handle it, valid or not.
      #
      # Can't use `all_blank?` because `position` has a
      # default value (0).
      def should_reject_audio?(attributes)
        attributes['mp3'].blank? &&
        attributes['enco_number'].blank? &&
        attributes['enco_date'].blank? &&
        attributes['url'].blank? &&
        attributes['description'].blank? &&
        attributes['byline'].blank?
      end
    end # AudioAssociation
  end # Associations
end # Concern
