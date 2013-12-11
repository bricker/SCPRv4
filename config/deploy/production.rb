require 'net/http'
require 'newrelic_rpm'

set :stage, :production
set :rails_env, :production
set :deploy_to, "/web/scprv4"
set :branch, "master"

set :ssh_options, {
  user: 'scprv4'
}

set :newrelic_license_key, NewRelic::Agent.config[:license_key]

web1  = "66.226.4.226"
web2  = "66.226.4.227"
web4  = "66.226.4.240"
media = "66.226.4.228"

role :web, [web2, web4] # Necessary for assets for now
role :app, [web2, web4, media]
role :workers, [media]
role :db, [web2], no_release: true
role :sphinx, [media], no_release: true


namespace :deploy do
  before :starting, 'deploy:notify'
  after :finishing, 'newrelic:notice_deployment'


  desc 'Restart application'
  task :restart do
    on roles(:workers) do
      touch_restart
    end

    on roles(:web), in: :sequence, wait: 30 do
      touch_restart
    end
  end
end
