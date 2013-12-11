set :stage, :staging
set :rails_env, :staging
set :deploy_to, "/web/scprv4"
set :branch, "master"

set :ssh_options, {
  user: 'scprv4'
}

scprdev = "66.226.4.241"
role :app, [scprdev]
role :workers, [scprdev]
role :db, [scprdev]
role :sphinx, [scprdev]

set :ts_index, false # Whether or not to run the sphinx index on drop
set :syncdb, false # Whether or not to run a dbsync to mercer_staging


namespace :deploy do
  before :migrate, "dbsync:pull"

  # The "migrate" task will be run before this (which is what we want),
  # since it gets registered first (via Capfile)
  after :updated, "thinking_sphinx:staging:index"
end


namespace :dbsync do
  task :pull do
    on roles(:app) do
      syncdb = fetch(:syncdb)

      if [true, 1].include? syncdb
        invoke "dbsync:pull"
      else
        info "[dbsync:pull] SKIPPING dbsync"
        debug "[dbsync:pull] syncdb set to #{syncdb}"
      end
    end
  end
end

namespace :thinking_sphinx do
  namespace :staging do
    desc "Run thinking_sphinx on the staging server"
    task :index do
      on roles(:sphinx) do
        ts_index = fetch(:ts_index)

        if [true, 1].include? ts_index
          invoke 'ts:rebuild'
        else
          info "[thinking_sphinx:staging:index] SKIPPING thinking_sphinx:index"
          debug "[thinking_sphinx:staging:index] ts_index set to #{ts_index}"
        end
      end
    end
  end
end
