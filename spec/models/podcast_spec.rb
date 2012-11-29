require "spec_helper"

describe Podcast do
  describe "validations" do
    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:url) }
    it { should validate_presence_of(:podcast_url) }
    
    it "validates slug uniqueness" do
      create :podcast
      should validate_uniqueness_of(:slug)
    end
  end
  
  #---------------
  
  describe "associations" do
    it { should belong_to(:source) }
    it { should belong_to(:category) }
  end
  
  #---------------

  describe "#content" do
    before :all do
      setup_sphinx
    end
    
    after :all do
      teardown_sphinx
    end
    
    context "for KpccProgram/OtherProgram" do
      it "grabs episodes when item_type is episodes" do
        episode = create :show_episode
        create :audio, :direct, content: episode

        index_sphinx

        podcast = create :podcast, source: episode.show, item_type: "episodes"
        podcast.content.to_a.should eq [episode]
      end
      
      it "grabs segments when item_type is segments" do
        segment = create :show_segment
        create :audio, :direct, content: segment

        index_sphinx
        podcast = create :podcast, source: segment.show, item_type: "segments"
        
        ts_retry(2) do
          podcast.content.to_a.should eq [segment]
        end
      end
    end
    
    context "for Blog" do
      it "grabs entries" do
        entry = create :blog_entry
        create :audio, :direct, content: entry

        index_sphinx
        podcast = create :podcast, source: entry.blog
        
        ts_retry(2) do
          podcast.content.to_a.should eq [entry]
        end
      end
    end
    
    context "for Content" do
      it "grabs content" do
        story   = create :news_story, published_at: 1.days.ago
        entry   = create :blog_entry, published_at: 2.days.ago
        segment = create :show_segment, published_at: 3.days.ago
        
        [story, entry, segment].each do |content|
          create :audio, :direct, content: content
        end
        
        index_sphinx
        podcast = create :podcast, item_type: "content", source: nil
        
        ts_retry(2) do
          podcast.content.to_a.should eq [story, entry, segment]
        end
      end
    end   
  end
end
