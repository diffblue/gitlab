# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::BaseBulkUpdateService, feature_category: :geo_replication do
  let(:service) { described_class.new('Geo::JobArtifactRegistry') }

  shared_examples 'a non implemented method' do |method|
    it 'raises `NotImplementedError`' do
      expect { service.send(method) }.to raise_error(NotImplementedError)
    end
  end

  describe '#bulk_mark_update_name' do
    it_behaves_like 'a non implemented method', :bulk_mark_update_name
  end

  describe '#attributes_to_update' do
    it_behaves_like 'a non implemented method', :attributes_to_update
  end

  describe '#pending_to_update_relation' do
    it_behaves_like 'a non implemented method', :pending_to_update_relation
  end
end
