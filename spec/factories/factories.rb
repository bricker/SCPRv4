FactoryGirl.define do

# Audio #########################################################
  factory :audio do    
    trait :uploaded do
      content { |a| a.association :news_story }
      mp3 File.open(Rails.application.config.scpr.media_root.join("audio/point1sec.mp3"))
    end
    
    trait :enco do
      content { |a| a.association :news_story }
      enco_number 1488
      enco_date { Date.today }
    end
    
    trait :direct do
      content { |a| a.association :news_story }
      mp3_path "events/2012/10/02/SomeCoolEvent.mp3"
    end

    trait :program do
      type "Audio::ProgramAudio" # Typecast this object since Audio#set_type doesn't do it for ProgramAudio
      mp3 File.open(Rails.application.config.scpr.media_root.join("audio/mbrand/20121002_mbrand.mp3"))
    end
    
    trait :for_episode do
      content { |a| a.association :show_episode }
    end
    
    trait :for_segment do
      content { |a| a.association :show_segment }
    end
    
    #---------
    
    factory :program_audio, class: "Audio::ProgramAudio" do
      for_episode
      program
    end
    
    factory :enco_audio, class: "Audio::EncoAudio" do
      enco
    end
    
    factory :direct_audio, class: "Audio::DirectAudio" do
      direct
    end
    
    factory :uploaded_audio, class: "Audio::UploadedAudio" do
      uploaded
    end
  end

# RecurringScheduleSlot #########################################################
factory :recurring_schedule_slot do
  sequence(:start_time) { |n| Time.new(2012, 10, 25, 1*n).second_of_week }
  end_time { start_time + 2.hours }  
  program { |f| f.association :kpcc_program }
end

# DistinctScheduleSlot #########################################################
factory :distinct_schedule_slot do
end


# Bio #########################################################
  factory :bio, class: "Bio", aliases: [:author] do
    user { |bio| bio.association :admin_user }
    sequence(:name) { |n| "Bryan Ricker #{n}" }

    is_public    true
    slug         { name.parameterize }
    twitter      { "@#{slug}" }
    
    bio          "This is a bio"
    short_bio    "Short!"
    title        "Rails Developer"
    phone_number "123-456-7890"
  end
  
# AdminUser #########################################################
  factory :admin_user do
    # To be removed:
    sequence(:first_name) { |n| "Bryan #{n}" }
    last_name   "Ricker"
    password    "sha1$vxA3aP5quIgd$aa7c53395bf8d6126c02ec8ef4e8a9b784c9a2f7" # `secret`, salted & digested
    date_joined { Time.now }
    #
    
    unencrypted_password "secret"
    unencrypted_password_confirmation { unencrypted_password }
    last_login { Time.now }
    sequence(:email) { |i| "user#{i}@scpr.org" }
    
    is_staff 1
    is_active 1
    is_superuser 1
    
    trait :staff_user do
      is_staff     1
      is_active    1
      is_superuser 0
    end
    
    trait :superuser do
      is_staff     1
      is_active    1
      is_superuser 1
    end
  end
  

# KpccProgram #########################################################
  factory :kpcc_program, aliases: [:show] do
    sequence(:title) { |n| "Show #{n}" }
    slug { title.parameterize }    
    air_status "onair"
    
    trait :episodic do
      display_episodes 1
    end
    
    trait :segmented do
      display_segments 1
    end
        
    ignore { segment Hash.new } # Ensures that `merge` has something to do in the after :create block
    ignore { episode Hash.new } # Ensures that `merge` has something to do in the after :create block
    ignore { missed_it_bucket Hash.new }
    ignore { episode_count 0 }
    ignore { segment_count 0 }
    ignore { blog false }
    
    after :create do |object, evaluator|
      FactoryGirl.create_list(:show_segment, evaluator.segment_count.to_i, evaluator.segment.merge!(show: object))
      FactoryGirl.create_list(:show_episode, evaluator.episode_count.to_i, evaluator.episode.merge!(show: object))
      
      if evaluator.blog == "true"
        object.blog = FactoryGirl.create :blog
        object.save!
      end
      
      if evaluator.missed_it_bucket_id.blank?
        object.missed_it_bucket = FactoryGirl.create(:missed_it_bucket, evaluator.missed_it_bucket.reverse_merge!(title: object.title))
        object.save!
      end
    end
  end
  

# OtherProgram #########################################################
  factory :other_program do
    sequence(:title) { |n| "Other Program #{n}" }
    slug        { title.parameterize }
    air_status  "onair"
    podcast_url "http://www.npr.org/rss/podcast.php?id=510005"
    rss_url     "http://www.kqed.org/rss/private/californiareport.xml"
  end
  

# ShowRundown #########################################################
  factory :show_rundown do
    episode
    segment
  end

# Podcast #########################################################
  factory :podcast do
    sequence(:title) { |n| "Podcast #{n}" }
    slug { title.parameterize }
    author "KPCC 89.3 | Southern California Public Radio"
    source { |p| p.association :kpcc_program }
    item_type 'episodes'
    podcast_url { "http://www.scpr.org/podcasts/loh_down" }
    image_url { "http://media.scpr.org/assets/images/podcasts/#{slug}.png" }
    keywords "KPCC, Los Angeles, Southern California, LA"
    url { "http://www.scpr.org/programs/#{slug}" }
    duration 0
  end


# Blog #########################################################
  factory :blog do
    sequence(:name) { |n| "Blog #{n}" }
    slug { name.parameterize }
    teaser { "This is the teaser for #{name}!" }
    description "This is a description for this blog."
    is_active true
    is_remote false
    is_news true
    feed_url "http://oncentral.org/rss/latest"
    custom_url "http://scpr.org" # it's a required field?
    
    trait :remote do
      is_remote true
      feed_url "http://oncentral.org/rss/latest"
    end
    
    ignore { author_count 0 }
    ignore { entry_count 0 }
    ignore { entry Hash.new }
    ignore { missed_it_bucket Hash.new }
  
    after :create do |object, evaluator|
      FactoryGirl.create_list(:blog_entry, evaluator.entry_count.to_i, evaluator.entry.merge!(blog: object))
      FactoryGirl.create_list(:blog_author, evaluator.author_count.to_i, blog: object)
      
      if evaluator.missed_it_bucket_id.blank?
        object.missed_it_bucket = FactoryGirl.create(:missed_it_bucket, evaluator.missed_it_bucket.reverse_merge!(title: object.name))
        object.save!
      end
    end
  end

# BreakingNewsAlert #########################################################
  factory :breaking_news_alert do
    headline      "Breaking news!"
    teaser        "This is breaking news"
    alert_time    { Time.now }
    alert_type    "break"
    alert_link    "http://scpr.org/"
    is_published  1
    visible       1
    email_sent    0
    send_email    0
  end

# BlogAuthor #########################################################
  factory :blog_author do
    blog
    author
    sequence(:position)
  end


# ContentAlarm #########################################################
  factory :content_alarm do
    content   { |alarm| alarm.association :news_story, :pending }
    
    trait :pending do
      fire_at   { Time.now - 2.hours }
    end
    
    trait :future do
      fire_at   { Time.now + 2.hours }
    end
  end
  
# Event #########################################################
  factory :event do
    sequence(:id, 1) # Not auto-incrementing in database?
    sequence(:headline)   { |n| "A Very Special Event #{n}" }
    sequence(:starts_at)  { |n| Time.now + 60*60*24*n }
    
    slug                { headline.parameterize }
    body                "This is a very special event."
    etype               "comm"
    
    trait :published do
      is_published true
    end
    
    trait :with_address do
      address_1 "123 Fake St."
      address_2 "Apt. A"
      city      "Pasadena"
      state     "CA"
      zip_code  "12345"
    end
    
    trait :multiple_days_past do
      starts_at { 3.days.ago }
      ends_at   { 1.day.ago }
    end
    
    trait :multiple_days_current do
      starts_at { 1.day.ago }
      ends_at   { 1.day.from_now }
    end
    
    trait :multiple_days_future do
      starts_at { 1.day.from_now }
      ends_at   { 3.days.from_now }
    end
    
    trait :past do
      starts_at { 3.hours.ago }
      ends_at   { 2.hours.ago }
    end
    
    trait :current do
      sequence(:starts_at) { |n| n.hours.ago }
      sequence(:ends_at)   { |n| n.hours.from_now }
    end
    
    trait :future do
      starts_at { 2.hours.from_now }
      ends_at   { 3.hours.from_now }
    end
      
    ignore { asset_count 0 }
    after :create do |event, evaluator|
      FactoryGirl.create_list(:asset, evaluator.asset_count.to_i, content: event)
    end
  end

# ContentEmail#########################################################
  factory :content_email do # Must pass in content
    from_email  "bricker@kpcc.org"
    to_email    "bricker@scpr.org"
    content { |email| email.association :content_shell }
  end

# ContentAsset#########################################################
  factory :asset, class: ContentAsset do
    sequence(:id, 1)
    sequence(:asset_order, 1)
    asset_id 33585 # Doesn't matter what this is because the response gets mocked
    sequence(:caption) { |n| "Caption #{n}" }
    content { |asset| asset.association :content_shell }
  end


# ContentByline #########################################################
  factory :byline, class: "ContentByline", aliases: [:content_byline] do # Requires we pass in "content"
    role    ContentByline::ROLE_PRIMARY
    user    { |byline| byline.association :author }
    content { |byline| byline.association(:news_story) } #TODO Need to be able to pass in any type of factory here
    name    "Dan Jones"
  end

  
# Category #########################################################
  factory :category do
    trait :is_news do 
      sequence(:title) { |n| "Local #{n}" }
      is_news true
    end

    trait :is_not_news do
      sequence(:title) { |n| "Culture #{n}" }
      is_news false
    end

    slug { title.parameterize }
    comment_bucket

    factory :category_news, traits: [:is_news]
    factory :category_not_news, traits: [:is_not_news]
    
    ignore { content_count 0 }
    ignore { content Hash.new }
    
    after :create do |object, evaluator|
      FactoryGirl.create_list(:news_story, evaluator.content_count.to_i, evaluator.content.merge!(category: object))
    end
  end


# BlogCategory #########################################################
  factory :blog_category do
    blog
    sequence(:title) { |n| "Category #{n}" }
    slug { title.parameterize }
    
    ignore { entry_count 0 }
    
    after :create do |object, evaluator|
      FactoryGirl.create_list(:blog_entry_blog_category, evaluator.entry_count.to_i, blog_category: object)
    end
  end
  
# BlogEntryBlogCategory #########################################################
  factory :blog_entry_blog_category do
    blog_category
    blog_entry
  end
  
  
# Tag #########################################################
  factory :tag do
    sequence(:name) { |n| "Some Cool Slug #{n}"}
    slug { name.parameterize }
  end

# TaggedContent #########################################################
  factory :tagged_content do
    # Content must be passed in
    tag
  end
    

# FeaturedCommentBucket #########################################################
  factory :featured_comment_bucket, aliases: [:comment_bucket] do
    sequence(:title) { |n| "Comment Bucket #{n}" }
  end
  
  
# FeaturedComment #########################################################
  factory :featured_comment do
    bucket  { |f| f.association :featured_comment_bucket }
    content { |mic| mic.association(:content_shell) }
    
    username  "bryanricker"
    excerpt   "This is an excerpt of the featured comment"
    
    trait :pending do
      status 3
      sequence(:published_at) { |n| Time.now + n.hours }
    end

    trait :published do
      status 5
      sequence(:published_at) { |n| Time.now - n.hours }
    end

    trait :draft do
      status 0
    end
  end
  
  
# Flatpage #########################################################
  factory :flatpage do
    sequence(:url)        { |n| "/about-#{n}/" }
    title                 "About"
    content               "This is the about content"
    enable_comments       0
    registration_required 0
    description           "This is the description"
    is_public             1
    template              "inherit"
  end


# Section #########################################################
  factory :section do
    sequence(:title)  { |n| "Section #{n}" }
    slug              { title.parameterize }    
  end
  
  factory :section_blog do
    section
    blog
  end
  
  factory :section_category do
    section
    category
  end
  
  factory :section_promotion do
    section
    promotion
  end

  
# Promotion #########################################################
  factory :promotion do
    sequence(:title)  { |n| "Promotion #{n}" }
    url               { "http://scpr.org/promotions/#{title.parameterize}" }
  end
  

# ContentCategory #########################################################
  factory :content_category do
    # Empty, forcing us to pass content and category every time we create one
  end

# Related #########################################################
factory :related_content, class: Related do
  sequence(:id, 1)

  factory :brel do # "brels" - needs content
    flag 0
    related { |brel| brel.association(:content_shell) } #TODO Need to be able to pass in any type of factory here
  end

  factory :frel do # "frels" - needs related
    flag 0
    content { |frel| frel.association(:content_shell) } #TODO Need to be able to pass in any type of factory here
  end
end
  
# Link #########################################################
  factory :link do
    sequence(:id, 1)
    title     "A Related Link"
    link      "http://oncentral.org"
    link_type "website"
  end

# Homepage #########################################################
factory :homepage do
  base "default"
  sequenced_published_at
  status 5
  
  trait :published do
    status 5
    published_at { 2.hours.ago }
  end
  
  ignore { missed_it_bucket Hash.new }
  ignore { contents_count 0 }
  
  after :create do |object, evaluator|
    FactoryGirl.create_list(:homepage_content, evaluator.contents_count.to_i, homepage: object)
    
    if evaluator.missed_it_bucket_id.blank?
      object.missed_it_bucket = FactoryGirl.create(:missed_it_bucket, evaluator.missed_it_bucket.reverse_merge!(title: "Homepage #{object.id}"))
      object.save!
    end
  end
end

# HomepageContent #########################################################
factory :homepage_content do
  homepage
  content { |hc| hc.association(:content_shell) }
end

# MissedItBucket #########################################################
factory :missed_it_bucket do
  sequence(:title) { |n| "Airtalk #{n}" }
  ignore { contents_count 0 }
  
  after :create do |object, evaluator|
    FactoryGirl.create_list(:missed_it_content, evaluator.contents_count.to_i, missed_it_bucket: object)
  end
end

# MissedItContent #########################################################
factory :missed_it_content do
  missed_it_bucket
  content { |mic| mic.association(:content_shell) }
end

# PijQuery #########################################################
factory :pij_query do
  sequence(:headline) { |n| "PIJ Query ##{n}"}
  body "Sweet PIJ query, bro"
  slug { headline.parameterize }  
  query_type "news"
  form_height 1500
  query_url "http://www.publicradio.org/applications/formbuilder/user/form_display.php"
  
  trait :utility do
    query_type "utility"
  end
  
  trait :evergreen do
    query_type "evergreen"
  end
  
  trait :news do
    query_type "news"
  end
  
  trait :featured do
    is_featured true
  end
  
  trait :visible do
    is_active true
    published_at  { 1.day.ago }
    expires_at    { 1.day.from_now }
  end
  
  trait :inactive do
    is_active     false
    published_at  { 1.day.ago }
    expires_at    { 1.day.from_now }
  end
  
  trait :unpublished do
    is_active     true
    published_at  { 1.day.from_now }
    expires_at    { 2.days.from_now }
  end
  
  trait :expired do
    is_active     { true }
    published_at  { 2.days.ago }
    expires_at    { 1.day.ago }
  end
end

# PressRelease #########################################################
factory :press_release do
  sequence(:short_title) { |n| "Press Release #{n}" }
  slug { short_title.parameterize }
end

# DataPoint #########################################################
factory :data_point do
  sequence(:data_key) { |i| "datapoint#{i}" }
end

end
