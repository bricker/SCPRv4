class RemoteArticle < ActiveRecord::Base
  # An importer MUST:
  # * Define a class method `sync`, which returns an array of
  #   RemoteArticles. This method is meant to sync the RemoteArticles
  #   database with that importer's API.
  # * Define an instance method `import`, which accepts the article
  #   to import and an options hash. This method is meant to
  #   define how a remote article is imported into a native type.

  include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation
  include Outpost::Model::Identifier
  include Outpost::Model::Naming
  logs_as_task

  IMPORTERS = {
    "npr" => "NprArticleImporter",
    "chr" => "ChrArticleImporter"
#    "pmp" => "PmpArticleImporter"
  }

  #---------------

  class << self
    include ::NewRelic::Agent::Instrumentation::ControllerInstrumentation

    def types_select_collection
      RemoteArticle.select("distinct source").order("source")
        .map(&:source)
    end

    #---------------
    # Since this class isn't getting (and, for the
    # most part, doesn't need) the Outpost
    # Routing, we'll just manually put this one here.
    def admin_index_path
      @admin_index_path ||= Rails.application.routes.url_helpers.send(
        "outpost_#{self.route_key}_path")
    end

    #---------------
    # Sync with the APIs
    def sync
      added = []
      IMPORTERS.values.each { |a| added += a.constantize.sync }
      added
    end

    add_transaction_tracer :sync, category: :task
  end


  def importer
    IMPORTERS[self.source].constantize
  end

  def import(options={})
    self.importer.import(self, options)
  end

  def async_import(options={})
    import_to_class = options[:import_to_class]
    Resque.enqueue(Job::ImportRemoteArticle, self.id, import_to_class)
  end
end
