$: << "."

module CacheTasks
  def self.view
    view = ActionView::Base.new(ActionController::Base.view_paths, {})
    view.extend ApplicationHelper
    view.extend WidgetsHelper
  end
  
  class Task
    attr_accessor :verbose
    
    def cache(content, partial, cache_key)
      cached = CacheTasks.view.render(partial: partial, object: content, as: :content)
      Rails.cache.write(cache_key, cached)
      true
    end
    
    #---------------
    
    def log(message)
      message = "*** #{message}"
      
      # Rails log always gets it
      Rails.logger.info message
      
      # STDOUT only gets it if requested
      if @verbose
        $stdout.puts message
      end
    end
  end # Task
end # CacheTasks

Dir["cache_tasks/*"].each { |f| require f }
