##
# AssetAssociation
#
# Association for Asset
#
module Concern
  module Associations
    module AssetAssociation
      extend ActiveSupport::Concern
      
      included do
        has_many :assets, {
          :class_name => "ContentAsset", 
          :as         => :content, 
          :order      => "asset_order", 
          :dependent  => :destroy,
          :autosave   => true
        }
      end

      #-------------------
      # Return the first asset in the given medium and size.
      # Returns nil if no assets are present.
      def primary_asset(size, format=:tag)
        self.assets.first.asset.send(size).send(format) if self.assets.present?
      end
      

      # Define these methods manually since Rails uses a cache (not method_missing 
      # directly) to call them, and we don't want (or need) to reset that.
      def assets_changed?
        attribute_changed?('assets')
      end

      def assets_was
        assets_changed? ? changed_attributes['assets'] : current_assets_json
      end


      #-------------------
      # #asset_json is a way to pass in a string representation
      # of a javascript object to the model, which will then be
      # parsed and turned into ContentAsset objects in the 
      # #asset_json= method.
      def asset_json
        current_assets_json.to_json
      end

      #-------------------
      # Parse the input from #asset_json and turn it into real
      # ContentAsset objects. 
      def asset_json=(json)
        # If this is literally an empty string (as opposed to an 
        # empty JSON object, which is what it would be if there were no assets),
        # then we can assume something went wrong and just abort.
        # This shouldn't happen since we're populating the field in the template.
        return if json.empty?
        @_original_assets ||= self.assets.dup

        json = Array(JSON.parse(json)).sort_by { |c| c["asset_order"].to_i }
        loaded_assets = []
        
        json.each do |asset_hash|
          new_asset = ContentAsset.new(
            :asset_id    => asset_hash["id"].to_i, 
            :caption     => asset_hash["caption"].to_s, 
            :asset_order => asset_hash["asset_order"].to_i
          )
          
          loaded_assets.push new_asset
        end
        
        loaded_assets_json = assets_to_simple_json(loaded_assets)

        # If the assets didn't change, there's no need to bother the database.        
        if current_assets_json != loaded_assets_json
          self.assets = loaded_assets

          # So we can properly track the status of the assets on an object.
          if original_assets_json == loaded_assets_json
            self.changed_attributes.delete('assets')
          else
            self.changed_attributes['assets'] = original_assets_json
          end
        end

        self.assets
      end


      private

      def original_assets_json
        assets_to_simple_json(@_original_assets)
      end

      def current_assets_json
        assets_to_simple_json(self.assets)
      end

      def assets_to_simple_json(array)
        Array(array).map(&:simple_json)
      end
    end # AssetAssociation
  end # Associations
end # Concern
