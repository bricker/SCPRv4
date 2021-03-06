ENV["RAILS_ENV"] ||= 'test'

require File.expand_path("../../config/environment", __FILE__)
Dir[Rails.root.join("spec/fixtures/db/*.rb")].each { |f| require f }
silence_stream(STDOUT) { FixtureMigration.new.up }

require 'rspec/rails'
require 'rspec/autorun'
require 'thinking_sphinx/test'
require 'database_cleaner'
require 'webmock/rspec'
require 'capybara/rspec'

Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

# Load all of our test classes, their indices, and their factories.
Dir[Rails.root.join("spec/fixtures/indices/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/fixtures/models/*.rb")].each { |f| require f }
Dir[Rails.root.join("spec/fixtures/factories/*.rb")].each { |f| require f }

WebMock.disable_net_connect!

RSpec.configure do |config|
  config.use_transactional_fixtures = false
  config.infer_base_class_for_anonymous_controllers = true
  config.filter_run focus: true
  config.run_all_when_everything_filtered = true
  config.order = 'random'

  config.include ActionView::TestCase::Behavior,
    :example_group => { file_path: %r{spec/presenters} }

  config.include FactoryGirl::Syntax::Methods
  config.include ThinkingSphinxHelpers
  config.include RemoteStubs
  config.include PresenterHelper
  config.include DatePathHelper
  config.include AudioCleanup
  config.include FormFillers,           type: :feature
  config.include AuthenticationHelper,  type: :feature
  config.include FactoryAttributesBuilder

  config.before :suite do
    DatabaseCleaner.clean_with :truncation
    load "#{Rails.root}/db/seeds.rb"
    DatabaseCleaner.strategy = :transaction

    FileUtils.rm_rf(
      Rails.application.config.scpr.media_root.join("audio/upload")
    )

    FileUtils.rm(
      Dir[Rails.root.join(ThinkingSphinx::Test.config.indices_location, '*')]
    )

    ThinkingSphinx::Test.init
    ThinkingSphinx::Test.start_with_autostop
  end

  config.before type: :feature do
    DatabaseCleaner.strategy = :truncation, { except: STATIC_TABLES }
  end

  config.before :all do
    DeferredGarbageCollection.start
  end

  config.before :each do
    WebMock.reset!

    stub_request(:get, %r|a\.scpr\.org\/api\/outputs|).to_return({
      :body => load_fixture("api/assethost/outputs.json"),
      :content_type => "application/json"
    })

    stub_request(:get, %r|a\.scpr\.org\/api\/assets|).to_return({
      :body => load_fixture("api/assethost/asset.json"),
      :content_type => "application/json"
    })

    stub_request(:post, %r|a\.scpr\.org\/api\/assets|).to_return({
      :body => load_fixture("api/assethost/asset.json"),
      :content_type => "application/json"
    })

    stub_request(:get, %r|\.mp3\z|).to_return({
      :content_type => 'audio/mpeg',
      :body         => load_fixture('media/audio/2sec.mp3')
    })

    DatabaseCleaner.start
  end

  config.after :each do
    DatabaseCleaner.clean
    Rails.cache.clear
    ActionMailer::Base.deliveries.clear
  end

  config.after :all do
    DeferredGarbageCollection.reconsider
  end

  config.after :suite do
    DatabaseCleaner.clean_with :truncation
  end
end
