require 'spec_helper'

describe Edition do
  describe '#slots' do
    it 'orders by position' do
      edition = build :edition
      edition.slots.to_sql.should match /order by position/i
    end
  end

  describe '::titles_collection' do
    it "is an array of all the published titles" do
      create :edition, :published, title: "Abracadabra"
      create :edition, :unpublished, title: "Marmalade"
      create :edition, :published, title: "Zealot"

      Edition.titles_collection.should eq ["Abracadabra", "Zealot"]
    end
  end

  describe '#title' do
    it "validates title when the edition is pending" do
      edition = build :edition, :pending, title: nil
      edition.should_not be_valid
      edition.errors.keys.should eq [:title]
    end

    it "validates title when the edition is published" do
      edition = build :edition, :published, title: nil
      edition.should_not be_valid
      edition.errors.keys.should eq [:title]
    end

    it "doesn't validate title when the edition is draft" do
      edition = build :edition, :unpublished, title: nil
      edition.should be_valid
    end
  end

  describe '#abstracts' do
    it 'turns all of the items into abstracts' do
      edition   = create :edition, :published
      story     = create :news_story
      slot      = create :edition_slot, edition: edition, item: story

      edition.abstracts.map(&:class).uniq.should eq [Abstract]
    end
  end

  describe '#articles' do
    it 'turns all of the items into articles' do
      edition   = create :edition, :published
      story     = create :news_story
      slot      = create :edition_slot, edition: edition, item: story

      edition.articles.map(&:class).uniq.should eq [Article]
    end
  end

  describe '#publish' do
    it 'sets the status to published' do
      edition = create :edition, :pending
      edition.published?.should eq false
      edition.publish

      edition.reload.published?.should eq true
    end
  end


  describe "sending the e-mail" do
    describe "job queue" do
      it "queues the job when email should be published" do
        edition = build :edition, :published
        edition.should_receive(:async_send_email)
        edition.save!
      end

      it "doesn't queue the job if the email was already sent" do
        edition = build :edition, :published, email_sent: true
        edition.should_not_receive(:async_send_email)
        edition.save!
      end

      it "doesn't queue the job if the edition isn't published" do
        edition = build :edition, :draft
        edition.should_not_receive(:async_send_email)
        edition.save!
      end

    end

    describe '#publish_email' do
      before do
        stub_request(:post, %r|assets/email|).to_return({
          :content_type   => "application/json",
          :body           => load_fixture("api/eloqua/email.json")
        })

        stub_request(:post, %r|assets/campaign/active|).to_return({
          :content_type   => "application/json",
          :body           => load_fixture("api/eloqua/campaign_activated.json")
        })

        stub_request(:post, %r|assets/campaign\z|).to_return({
          :content_type   => "application/json",
          :body           => load_fixture("api/eloqua/email.json")
        })

        # Just incase, we don't want this method queueing anything
        # since we're testing the publish method directly.
        Edition.any_instance.stub(:async_send_email)
      end

      it "sends an e-mail if the edition is published" do
        edition = create :edition, :published, :with_abstract
        edition.publish_email
        edition.email_sent?.should eq true
      end

      it "doesn't send an e-mail if the edition is not published" do
        edition = create :edition, :draft
        edition.publish_email
        edition.email_sent?.should eq false
      end

      it "doesn't send an e-mail if one has already been sent" do
        edition = create :edition, :published, email_sent: true
        edition.should_not_receive(:update_column).with(:email_sent, true)
        edition.publish_email
      end
    end
  end

  describe '#as_eloqua_email' do
    let(:edition) {
      build :edition, title: "Hundreds Die in Fire; Grep Proops Unharmed"
    }

    let(:abstract) { build :abstract }

    before do
      edition.slots.build(item: abstract)
      edition.save!
    end


    describe 'html_body' do
      it 'is a string containing some html' do
        edition.as_eloqua_email[:html_body].should match /<html/
      end
    end

    describe 'plain_text_body' do
      it 'is a string containing some text' do
        edition.as_eloqua_email[:plain_text_body].should match edition.title
      end
    end

    describe 'name' do
      it 'is a string with part of the title in it' do
        edition.as_eloqua_email[:name]
          .should eq "[scpr-edition] #{edition.title[0..30]}"
      end
    end

    describe 'description' do
      it 'has the title and abstract title' do
        description = edition.as_eloqua_email[:description]
        description.should match edition.title
        description.should match abstract.headline
      end
    end

    describe 'subject' do
      it 'has the title and abstract title' do
        subject = edition.as_eloqua_email[:subject]
        subject.should match edition.title
        subject.should match abstract.headline
      end
    end
  end
end
