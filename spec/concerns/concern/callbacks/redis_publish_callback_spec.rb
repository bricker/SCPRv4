require "spec_helper"

describe Concern::Callbacks::RedisPublishCallback do
  it "fires when publishing" do
    story = build :test_class_story, :published
    Publisher.should_receive(:publish)
    story.save!
  end

  it "fires when unpublishing" do
    story = create :test_class_story, :published

    Publisher.should_receive(:publish)

    story.status = story.class.status_id(:pending)
    story.save!
  end

  it "fires when status wasn't changed" do
    story = create :test_class_story, :published
    Publisher.should_receive(:publish)
    story.save!
  end

  it "fires when status was changed unpublished -> unpublished" do
    story = create :test_class_story, :published
    Publisher.should_receive(:publish)
    story.status = story.class.status_id(:pending)
    story.save!
  end
end
