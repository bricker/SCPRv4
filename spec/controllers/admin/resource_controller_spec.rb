require "spec_helper"

describe Admin::ResourceController do
  describe "get_record" do
    it "returns the record if it exists" do
      record = create :news_story
      controller.stub!(:params).and_return({ id: record.id })
      controller.stub!(:resource_class) { NewsStory }
      
      controller.get_record.should eq record
    end
    
    it "raises a RecordNotFound if ID does not exist" do
      controller.stub!(:params) { { id: "000" } }
      controller.stub!(:resource_class) { NewsStory }
      -> { controller.get_record }.should raise_error ActiveRecord::RecordNotFound
    end
  end
  
  describe "get_records" do
    pending
  end
  
  describe "resource_class" do
    pending
  end
  
  describe "extend_breadcrumbs_with_resource_route" do
    pending
  end
end