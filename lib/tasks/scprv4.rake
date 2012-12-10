namespace :scprv4 do 
  desc "Place a full sphinx index into the queue"
  task :enqueue_index => [:environment] do
    puts "*** [#{Time.now}] Enqueueing sphinx index into Resque..."    
    indexer = Indexer.new
    indexer.enqueue
    puts "Finished."
  end

  #----------
  
  desc "Clear events cache"
  task :clear_events => [ :environment ] do 
    Rails.cache.expire_obj("events/event:new")
  end

  #----------
  
  desc "Fire pending content alarms"
  task :fire_content_alarms => [:environment] do
    puts "*** [#{Time.now}] Firing pending content alarms..."
    ContentAlarm.fire_pending
    puts "Finished."
  end

  #----------
  
  desc "Sync all Audio types"
  task :syncaudio => [:environment] do
    puts "*** [#{Time.now}] Enqueueing audio sync tasks into Resque..."
    Audio.enqueue_all
    puts "Finished."
  end

  #----------
  
  desc "Cache everything"
  task :cache => [:environment] do
    Rake::Task["scprv4:cache:remote_blogs"].invoke
    Rake::Task["scprv4:cache:programs"].invoke
    Rake::Task["scprv4:cache:homepage"].invoke
    Rake::Task["scprv4:cache:most_viewed"].invoke
    Rake::Task["scprv4:cache:most_commented"].invoke
    Rake::Task["scprv4:cache:twitter"].invoke
  end
  
  #----------
  
  namespace :cache do
    desc "Cache Remote Blog Entries"
    task :remote_blogs => [:environment] do
      puts "Caching remote blogs..."
      cached = Blog.cache_remote_entries
      puts "Finished.\n"
    end
    
    #----------
    
    desc "Cache Most Viewed"
    task :most_viewed => [:environment] do
      puts "*** [#{Time.now}] Caching most viewed..."

      analytics = API_KEYS["google"]["analytics"]
      task = CacheTasks::MostViewed.new(
        analytics["client_id"],
        analytics["client_secret"],
        analytics["token"],
        analytics["refresh_token"]
      )

      task.verbose = true
      task.run
      puts "Finished.\n"
    end

    #----------
    
    desc "Cache Most Commented"
    task :most_commented => [:environment] do
      puts "*** [#{Time.now}] Caching most commented..."
      task = CacheTasks::MostCommented.new("kpcc", "3d", API_KEYS['disqus']['api_key'], 5)
      task.verbose = true
      task.run
      puts "Finished.\n"
    end

    #----------
    
    desc "Cache KPCCForum tweets"
    task :twitter => [:environment] do
      puts "*** [#{Time.now}] Caching KPCCForum tweets...."
      task = CacheTasks::Twitter.new("KPCCForum")
      task.verbose = true
      task.run
      puts "Finished.\n"
    end
    
    #----------
    
    desc "Cache external programs"
    task :programs => [ :environment ] do
      puts "Caching remote programs..."
      OtherProgram.active.each { |p| p.cache }
      puts "Finished.\n"
    end
    
    #----------
    
    desc "Cache homepage one time"
    task :homepage => [ :environment ] do
      puts "*** [#{Time.now}] Caching homepage..."
      task = CacheTasks::Homepage.new
      task.verbose = true
      task.run
      puts "Finished.\n"
    end
  end
  
  #----------
  
  namespace :worker do
    desc "Start a Homepage listener"
    task :homepage => [ :environment ] do
      require 'homepage_worker'
    
      begin
        worker = HomepageWorker.new()
        worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      rescue
        abort "Failed to launch HomepageWorker!"
      end
    
      if ENV['BACKGROUND']
        Process.daemon(true)
      end
    
      if ENV['PIDFILE']
        File.open(ENV['PIDFILE'], 'w') { |f| f << worker.pid }
      end
    
      worker.log "Starting worker #{worker}"
      worker.work()
    end
    
    #----------
    
    desc "Start an Email listener"
    task :email => [ :environment ] do 
      require 'email_worker'
    
      begin
        worker = EmailWorker.new()
        worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      rescue
        abort "Failed to launch EmailWorker!"
      end
    
      if ENV['BACKGROUND']
        Process.daemon(true)
      end
    
      if ENV['PIDFILE']
        File.open(ENV['PIDFILE'], 'w') { |f| f << worker.pid }
      end
    
      worker.log "Starting worker #{worker}"
      worker.work()
    end
  
    #----------
  
    desc "Start an assethost listener"
    task :assets => [ :environment ] do 
      require 'asset_worker'
    
      begin
        worker = AssetWorker.new()
        worker.verbose = ENV['LOGGING'] || ENV['VERBOSE']
      rescue
        abort "Failed to launch AssetWorker!"
      end
    
      if ENV['BACKGROUND']
        Process.daemon(true)
      end
    
      if ENV['PIDFILE']
        File.open(ENV['PIDFILE'], 'w') { |f| f << worker.pid }
      end
    
      worker.log "Starting worker #{worker}"
      worker.work()
    end
  end
end
