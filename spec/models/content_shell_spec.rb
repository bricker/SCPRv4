require 'spec_helper'

describe ContentShell do
  describe "scopes" do
    it_behaves_like "since scope"
    
    describe "#published" do      
      it "orders published content by published_at descending" do      
        ContentShell.published.to_sql.should match /order by published_at desc/i
      end
    end
  end

  #-----------------
  
  describe "associations" do
    it_behaves_like "content alarm association"
    it_behaves_like "asset association"
  end

  #-----------------
  
  describe "callbacks" do
    #
  end
  
  #-----------------

  describe "validations" do
    it_behaves_like "content validation"
    it_behaves_like "published at validation"
  end

  #-----------------
  
  it_behaves_like "status methods"
  it_behaves_like "publishing methods"
  
  describe "#remote_link_path" do
    it "uses the url attribute" do
      shell = build :content_shell
      shell.remote_link_path.should eq shell.url
    end
  end
  
  #-----------------
  
  describe "comments" do
    it "doesn't respond to disqus_identifier" do
      build(:content_shell).should_not respond_to :disqus_identifier
    end
  end
  
  #--------------------

  describe "#body" do
    it "is the teaser" do
      content_shell = build :content_shell
      content_shell.body.should eq content_shell.teaser
    end
  end
  
  #-----------------
  
  describe "#link_path" do
    it "uses the url attribute" do
      shell = build :content_shell
      shell.link_path.should eq shell.url
    end
  end
  
  #-----------------
end