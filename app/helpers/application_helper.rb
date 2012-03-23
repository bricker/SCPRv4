module ApplicationHelper
  include Twitter::Autolink
  
  # render_content takes a ContentBase object and a context, and renders 
  # using the most specific version of that context it can find.
  # 
  # For instance, if your content is a "news/story" and your context is 
  # "lead", render_content will try:
  # 
  # * shared/content/news/story/lead
  # * shared/content/news/lead
  # * shared/content/default/lead

  
  def render_content(content,context,options={})
    if !content
      return ''
    end
    
    html = ''
    
    [content].flatten.each do |c|
      if c.respond_to?(:content) && c.content.is_a?(ContentBase)
        c = c.content
      end
      
      # if this isn't a contentbase object, assume it is broken and move on
      if !c.is_a?(ContentBase)
        next
        
        # FIXME: Should we also be raising a notification?
      end

      # if we're caching, add content to the objects list
      if defined? @COBJECTS
        @COBJECTS << c
      end
      
      # break up our content type
      types = c.class::CONTENT_TYPE.split("/")

      # set up our template precendence
      tmplt_opts = [
        [types[0],types[1],context].join("/"),
        [types[0],context].join("/"),
        ['default',context].join("/")
      ]

      partial = tmplt_opts.detect { |t| self.lookup_context.exists?(t,["shared/content"],true) }
      
      Rails.logger.debug "calling partial #{partial} for #{c}"
      
      html << render(options.merge({:partial => "shared/content/#{partial}", :object => c, :as => :content}))
    end
    
    return html.html_safe
  end
  
  #----------
  
  # render_asset takes a ContentBase object and a context, and renders using 
  # an optional context_asset_scheme attribute on the object.  
  #
  # For example, given a context of "story", render_asset will check for a 
  # story_asset_scheme attribute on the object.  If found (let's assume with a 
  # value of "wide"), it will try to render:
  #
  # * shared/assets/story/wide
  # * shared/assets/default/wide
  # * shared/assets/story/default
  # * shared/assets/default/default
  
  def render_asset(content,context)
    # short circuit if it's obvious we're getting nowhere
    if !content || !content.respond_to?("assets") || !content.assets.any?
      return ''
    end

    # look for a scheme on the content object
    scheme = content["#{context}_asset_scheme"] || "default"

    # set up our template precendence
    tmplt_opts = [
      "#{context}/#{scheme}",
      "default/#{scheme}",
      "#{context}/default",
      "default/default"
    ]
    
    partial = tmplt_opts.detect { |t| self.lookup_context.exists?(t,["shared/assets"],true) }

    render :partial => "shared/assets/#{partial}", :object => content.assets, :as => :assets, :locals => { :content => content }
  end
  
  #----------
  
  def smart_date(content,options={})
    options = {
      :today_template => "%-I:%M%P",
      :template       => "%b %e, %Y"
    }.merge(options)
    
    if !content || !content.respond_to?("public_datetime")
      return ""
    end
    
    if content.public_datetime.to_date == Date.today()
      if content.public_datetime.is_a? Time
        return content.public_datetime.strftime(options[:today_template])          
      else
        return "| Today"
      end
    elsif options && options[:today]
      # we only want a date if it is today's date, so return nothing
      return ''
    else
      return content.public_datetime.strftime(options[:template])
    end
  end
  
  def smart_date_js(content, options={})
    # If we pass in something that's not a Time-y object, then look for a "published_at" attribute. Only create the time tag if there is a time-y object to work with, otherwise the tag is useless.
    if content.respond_to?(:strftime) # This is a Time or DateTime object (or something similar)
      datetime = content
    elsif content.respond_to?(:published_at) # This is an object with a published_at attribute
      datetime = content.published_at
    end
    
    if datetime ||= nil
      content_tag(:time, '', { class: "#{options[:class] + " " if options[:class]}smart smarttime", "datetime" => datetime.strftime("%FT%R"), "data-unixtime" => datetime.to_i }.merge!(options.except(:class)))  
    else
      return nil
    end
  end
  
  #----------
  
  def render_byline(content,links = true)
    if !content || !content.respond_to?(:sorted_bylines)
      return ""
    end    
    
    authors = content.sorted_bylines
        
    # go through each list and add links where needed
    names = []
    (0..1).each do |i|
      if !authors[i] || !authors[i].any?
        next
      end
      
      authors[i].collect! do |b|
        if links && b.user
          link_to(b.user.name, bio_path(b.user.slugged_name))
        elsif b.user
          b.user.name
        else
          b.name
        end
      end
        
      if authors[i].length == 1
        names << authors[i][0]
      elsif authors[i].length > 1
        names << [ authors[i].pop,authors[i].join(", ") ].reverse.join(' and ')
      end
    end
    
    # add on any byline elements
    
    byels = content.byline_elements.collect { |e| e && e != '' ? e : nil }.compact
    
    if byels.length > 0
      if authors[0].length == 0 and authors[1].length == 0
        return byels.join(" | ").html_safe
      else
        return ("By " + [names.join(" with "), byels.join(" | ")].join(" | ")).html_safe
      end
    else
      if names.any?
        return ("By " + names.join(" with ")).html_safe
      else
        return ""
      end
    end
  end
  
  #----------
  
  def render_contributing_byline(content,links=true)
    if !content || !content.respond_to?(:sorted_bylines)
      return ""
    end    
    
    authors = content.sorted_bylines
    
    if authors[2] && authors[2].any?
      # go through each list and add links where needed
      authors[2].collect! do |b|
        if links && b.user
          link_to(b.user.name, bio_path(b.user.slugged_name))
        elsif b.user
          b.user.name
        else
          b.name
        end
      end    
    
      return "With contributions by #{ authors[2].length == 1 ? authors[2][0] : [ authors[2].pop,authors[2].join(", ") ].reverse.join(' and ') }.".html_safe
    
    else
      return ""
    end
  end
  
  # Convert a given number of seconds into a human-readable duration. 
  
  def format_duration(secs)
    if !secs
      return ''
    end
    
    [[60, :sec], [60, :min], [24, :hr], [1000, :days]].map{ |count, name|
      if secs > 0
        secs, n = secs.divmod(count)
        "#{n.to_i} #{name}"
      end
    }.compact.reverse.join(' ')
  end
  
  #----------
  
  def get_latest_arts
    begin
      ThinkingSphinx.search '',
        :classes    => ContentBase.content_classes,
        :page       => 1,
        :per_page   => 12,
        :order      => :published_at,
        :sort_mode  => :desc,
        :with       => { :category_is_news => false },
        :without    => { :category => '' }
    rescue Riddle::ConnectionError # If Sphinx is not running.
      return "Arts currently unavailable."
    end
  end
  
  #----------
  
  def get_latest_news
    begin
      ThinkingSphinx.search '',
        :classes    => ContentBase.content_classes,
        :page       => 1,
        :per_page   => 12,
        :order      => :published_at,
        :sort_mode  => :desc,
        :with       => { :category_is_news => true }
    rescue Riddle::ConnectionError # If Sphinx is not running.
      return "News currently unavailable."
    end
  end
  
  # any_to_list?: A graceful fail-safe for any Enumerable that might be blank
  # With block: t will return the block if there are records, or a message if there are no records.
  # Without block: Behaves the same as `.present?`
  # Options: 
  ### wrapper: a tag to use for the wrapper. Pass false if you do not want a wrapper
  ### title: What to call the records. If you don't pass this or a message, it will return a generic message if there are no records.
  ### message: Custom message to return if there are no records.
  def any_to_list?(records, options={}, &block)
    if records.present?
      block_given? ? capture(&block) : true
    else
      if block_given?
        if options[:message].blank?
          if options[:title].present?
            options[:message] = "There are currently no #{options[:title]}".html_safe
          else
            options[:message] = "There is nothing here to list.".html_safe
          end
        end
        return options[:message] if options[:wrapper] == false
        options[:wrapper] = :span if options[:wrapper].blank? || options[:wrapper] == true
        return content_tag(options[:wrapper], options[:message], class: "none-to-list")
      else
        return false
      end
    end
  end
  
  def page_title(elements, separator=" | ")
    if elements.is_a? Array
      @PAGE_TITLE = elements.join(separator)
    else
      @PAGE_TITLE = elements.to_s
    end
  end
  
  #----------
  
  def link_to_audio(title, object, options={}) # This needs to be more useful
    options[:class] = "audio-toggler #{options[:class]}"
    options[:title] ||= object.headline
    options["data-duration"] = object.audio.first.duration
    content_tag :div, link_to(title, object.audio.first.url, options), class: "story-audio inline"
  end
  
  def format_date(date, options={})
    return nil if !date.respond_to?(:strftime)
    formatted = date.strftime(options[:with]) if options[:with].present?
    case options[:format].to_s
      when "numbers"
        formatted = date.strftime("%m-%e-%y") # 10-11-11
      when "full_date"
        formatted = date.strftime("%B #{date.day.ordinalize}, %Y") # October 11th, 2011
      when "event"
        formatted = date.strftime("%A, %B %e") # Wednesday, October 11
    end
    formatted ||= date.strftime("%b %e, %Y") # Oct 11, 2011
  end
  
  def event_link(event, options={})
    return nil if !event.respond_to?(:starts_at)
    options.reverse_merge!(class: "event-link")
    return link_to(format_date(event.starts_at, format: :event), event.link_path, options)
  end
  
  def modal(options={}, &block)
    content_for :modal_content, capture(&block)
    render 'shared/modal_shell', options.reverse_merge!(cssClass: "", id: "")
  end
  
  def find_gmaps
    content_for :headerjs, javascript_include_tag("http://maps.googleapis.com/maps/api/js?key=#{API_Keys["google_maps"]}&sensor=false")
    content_for :footerjss, "var gmapsLoader = new scpr.GMapsLoader();"
  end
end
