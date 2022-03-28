# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActsAsTaggableOn::Tag' do
  describe '.find_or_create_all_with_like_by_name' do
    let(:tag_name) { 'tag' }

    subject(:find_or_create) { ActsAsTaggableOn::Tag.find_or_create_all_with_like_by_name(tag_name) }

    it 'creates a tag' do
      expect { find_or_create }.to change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it 'retries and finds tag if tag with same name created concurrently', :delete do
      expect(ActsAsTaggableOn::Tag).to receive(:create).with(name: tag_name) do
        # Simulate concurrent tag creation
        Thread.new do
          ActsAsTaggableOn::Tag.new(name: tag_name).save!
        end.join

        raise ActiveRecord::RecordNotUnique
      end

      expect { find_or_create }.to change(ActsAsTaggableOn::Tag, :count).by(1)
    end

    it 'raises error after 3 retries' do
      expect(ActsAsTaggableOn::Tag).to receive(:create).with(name: tag_name) do
        raise ActiveRecord::RecordNotUnique
      end.exactly(3).times

      expect { find_or_create}.to raise_error(ActsAsTaggableOn::DuplicateTagError)
    end
  end
end
