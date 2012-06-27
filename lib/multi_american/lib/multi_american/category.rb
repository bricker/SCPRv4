module WP
  class Category < Node
    XPATH = "/rss/channel/wp:category"
    SCPR_CLASS = "BlogCategory"
    
    instance_variable_set(:@queue, Rails.application.config.scpr.resque_queue)
    
    DEFAULTS = {
      blog_id: MultiAmerican::BLOG_ID
    }
    
    XML_AR_MAP = {
      # XML                 # AR
      category_nicename:    :slug,
      cat_name:             :title
    }
    
    administrate!
    self.list_fields = [
      ['id', title: "Term ID"],
      ['cat_name', link: true, title: "Name"],
      ['category_nicename', title: "Slug"]
    ]
    
    # -------------------
    # Class
    
    class << self

      # -------------------      
      # Elements
      def elements(doc)
        @elements ||= doc.xpath(XPATH)
      end
      
      # -------------------      
      # Resque
      def after_perform(*args)
        Rails.logger.info "Performed #{@queue}, sending to #{args[0]["to"]}"
        NodePusher.publish("finished_queue", args[0]["to"], args)
      end
        
      def perform(*args)
        Rails.logger.info "Performing #{@queue} with #{args}"
        sleep 5
        true
      end
      
    end
    
    # -------------------
    # Instance
    
    def import
      object_builder = {}
      XML_AR_MAP.each do |wp_attr, ar_attr|
        object_builder.merge!(ar_attr => send(wp_attr))
      end
      
      object_builder.reverse_merge!(DEFAULTS)
      object = SCPR_CLASS.constantize.new(object_builder)
      
      object.save
    end
    
    # -------------------
    # Convenience Methods
    
    def id
      term_id
    end
    
    def to_title
      cat_name
    end
  end
end