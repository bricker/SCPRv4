set :stage, :staging
set :rails_env, :staging
set :deploy_to, "/web/scprv4"
set :branch, "master"

set :ssh_options, {
  user: 'scprv4'
}

scprdev = "66.226.4.241"
role :web, [scprdev] # Necessary for assets for now
role :app, [scprdev]
role :workers, [scprdev], no_release: true
role :db, [scprdev], no_release: true
role :sphinx, [scprdev], no_release: true


namespace :deploy do
  before :migrate, "dbsync:pull"

  # The "migrate" task will be run before this (which is what we want),
  # since it gets registered first (via Capfile)
  after :updated, "thinking_sphinx:staging:index"


  desc 'Restart application'
  task :restart do
    on roles(:app) do
      touch_restart
    end
  end
end


namespace :dbsync do
  task :pull do
    on roles(:app) do
      syncdb = ENV['SYNCDB']

      if syncdb
        rake_remote "dbsync:pull"
      else
        info "[dbsync:pull] SKIPPING dbsync"
        debug "[dbsync:pull] set SYNCDB=1 to run this task."
      end
    end
  end
end


namespace :thinking_sphinx do
  namespace :staging do
    desc "Run thinking_sphinx on the staging server"
    task :index do
      on roles(:sphinx) do
        ts_index = ENV['TS_INDEX']

        if ts_index
          rake_remote 'ts:rebuild'
        else
          info "[thinking_sphinx:staging:index] SKIPPING thinking_sphinx:index"

          debug "[thinking_sphinx:staging:index] " \
                "set TS_INDEX=1 to run this task"
        end
      end
    end
  end
end
