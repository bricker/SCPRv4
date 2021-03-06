require 'spec_helper'

describe Concern::Associations::FeatureAssociation do
  describe '#feature' do
    it "gets the aricle's feature" do
      story = create :test_class_story, feature_type_id: 1

      story.feature.key.should eq :slideshow
    end

    it "is nil if it doesn't have a feature" do
      story = create :test_class_story, feature_type_id: nil

      story.feature.should be_nil
    end
  end


  describe '#feature=' do
    let(:feature) { ArticleFeature.find_by_id(1) }

    context 'with ArticleFeature' do
      it 'assigns the feature' do
        story = create :test_class_story, feature_type_id: nil

        story.feature = feature
        story.feature_type_id.should eq 1
      end
    end

    context 'with String' do
      it 'assigns the feature' do
        story = create :test_class_story, feature_type_id: nil

        story.feature = "slideshow"
        story.feature_type_id.should eq 1
      end
    end

    context 'with Symbol' do
      it 'assigns the feature' do
        story = create :test_class_story, feature_type_id: nil

        story.feature = :slideshow
        story.feature_type_id.should eq 1
      end
    end

    context 'with Integer' do
      it 'assigns the feature' do
        story = create :test_class_story, feature_type_id: nil

        story.feature = 1
        story.feature_type_id.should eq 1
      end
    end

    context 'with NilClass' do
      it 'unassigns the feature' do
        story = create :test_class_story, feature_type_id: 1

        story.feature.should eq feature
        story.feature = nil
        story.feature_type_id.should be_nil
      end
    end
  end
end
