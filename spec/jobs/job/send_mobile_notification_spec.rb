require 'spec_helper'

describe Job::SendMobileNotification do
  subject { described_class }
  its(:queue) { should eq "scprv4:mid_priority" }

  before :each do
    stub_request(:post, %r|api\.parse\.com|)
    .to_return(body: { result: true }.to_json)
  end

  context "with breaking news alert" do
    describe '::perform' do
      it 'sends the mobile notification' do
        alert = create :breaking_news_alert, :mobile, :published
        alert.mobile_notification_sent?.should eq false

        Job::SendMobileNotification.perform("BreakingNewsAlert", alert.id)
        alert.reload.mobile_notification_sent?.should eq true
      end
    end
  end
end
