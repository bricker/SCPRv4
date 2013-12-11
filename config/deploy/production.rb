require 'new_relic/recipes'
require 'net/http'

set :stage, :production
set :branch, "master"

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
