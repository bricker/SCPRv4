# See the Twitter API docs for more available options:
# https://dev.twitter.com/docs/api/1/get/statuses/user_timeline

module Job
  class TwitterCache < Base
    @priority = :low

    DEFAULTS = {
      :count            => 6,
      :trim_user        => 0,
      :include_rts      => 1,
      :exclude_replies  => 1,
      :include_entities => 0
    }


    class << self
      def perform(screenname, partial, key, options={})
        job = new(screenname, options)

        tweets = job.fetch

        if tweets.present?
          self.cache(tweets, partial, key)
        end
      end
    end


    def initialize(screen_name, options={})
      @tweeter     = Tweeter.new("kpccweb")
      @screen_name = screen_name
      @options     = options.reverse_merge(DEFAULTS)
    end


    def fetch
      begin
        self.log  "Fetching the latest #{@options[:count]} tweets " \
                  "for #{@screen_name}..."

        @tweeter.user_timeline(@screen_name, @options)
      rescue => e
        warn "Error caught in TwitterCache#fetch: #{e}"
        self.log "Error: \n #{e}"
        false
      end
    end

    add_transaction_tracer :fetch, category: :task
  end # TwitterCache
end # Job
