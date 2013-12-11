set :stage, :staging
set :branch, "master"

scprdev = "66.226.4.241"
role :app, [scprdev]
role :workers, [scprdev]
role :db, [scprdev]
role :sphinx, [scprdev]

namespace :deploy do
  after :updated, "dbsync:pull", "thinking_sphinx:staging:index"
end


namespace :dbsync do
  task :pull do
    if [true, 1].include? syncdb
      invoke "dbsync:pull"
    else
      logger.info "SKIPPING dbsync (syncdb set to #{syncdb})"
    end
  end
end

namespace :thinking_sphinx do
  namespace :staging do
    task :index do
      if [true, 1].include? ts_index
        thinking_sphinx.index
      else
        logger.info "SKIPPING thinking_sphinx:index (ts_index set to #{ts_index})"
      end
    end
  end
end
