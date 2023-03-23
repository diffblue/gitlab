# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Eventable, feature_category: :geo_replication do
  describe '.up_to_event' do
    it 'finds only events up to the given geo event log id' do
      events = create_list(:geo_event_log, 4, :updated_event)

      expect(Geo::RepositoryUpdatedEvent.up_to_event(events.second.id)).to match_array(events.first(2).map(&:event))
    end
  end

  describe '.delete_with_limit' do
    it 'deletes a limited amount of rows' do
      create_list(:geo_event_log, 4, :updated_event)

      expect do
        Geo::RepositoryUpdatedEvent.delete_with_limit(2)
      end.to change { Geo::RepositoryUpdatedEvent.count }.by(-2)
    end
  end

  describe '#consumer_klass_name' do
    it 'returns the even class name without the module part' do
      event = build_stubbed(:geo_repository_created_event)

      expect(event.consumer_klass_name).to eq 'RepositoryCreatedEvent'
    end
  end
end
