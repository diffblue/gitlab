# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::CacheInvalidationEventStore, feature_category: :geo_replication do
  include EE::GeoHelpers

  let_it_be(:secondary_node) { create(:geo_node) }

  let(:cache_key) { 'cache-key' }

  subject { described_class.new(cache_key) }

  describe '#initialize' do
    context 'when the key is a String' do
      it 'does not modify the key' do
        expect(subject.key).to eq(cache_key)
      end
    end

    context 'when the key is an Array' do
      let(:cache_key) { %w{a cache key} }

      it 'expands the key' do
        expect(subject.key).to eq('a/cache/key')
      end
    end
  end

  describe '#create' do
    it_behaves_like 'a Geo event store', Geo::CacheInvalidationEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks the cache key that should be invalidated' do
        subject.create!

        expect(Geo::CacheInvalidationEvent.last).to have_attributes(key: cache_key)
      end

      it 'logs an error message when event creation fail' do
        subject = described_class.new(nil)

        expected_message = {
          class: described_class.name,
          gitlab_host: "localhost",
          cache_key: '',
          message: 'Cache invalidation event could not be created',
          error: "Validation failed: Key can't be blank"
        }

        expect(Gitlab::Geo::Logger).to receive(:error)
          .with(expected_message).and_call_original

        subject.create!
      end
    end
  end
end
