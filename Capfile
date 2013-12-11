$deploy_time = Time.now.to_i

Bundler.require(:deployment)

def rake_remote(command, *args)
  within release_path do
    with rails_env: fetch(:rails_env) do
      execute :rake, command, *args
    end
  end
end

def touch_restart
  tmp = release_path.join('tmp')

  if test "[ -f #{tmp} ]"
    execute :mkdir, tmp
  end

  execute :touch, release_path.join('tmp/restart.txt')
end


# Load DSL and Setup Up Stages
require 'capistrano/setup'

# Includes default deployment tasks
require 'capistrano/deploy'

# Includes tasks from other gems included in your Gemfile
require 'capistrano/rails'

set :thinking_sphinx_roles, [:sphinx]

# Loads custom tasks from `lib/capistrano/tasks' if you have any defined.
Dir.glob('lib/capistrano/tasks/*.cap').each { |r| import r }
