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

role :app, [web2, web4]
role :workers, [media]
role :db, [web2]
role :sphinx, [media]

namespace :deploy do
  before :starting, 'deploy:notify'
  after :finishing, 'newrelic:notice_deployment'
end
