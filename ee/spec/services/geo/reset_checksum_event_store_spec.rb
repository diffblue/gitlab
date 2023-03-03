# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ResetChecksumEventStore, feature_category: :geo_replication do
  include EE::GeoHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:secondary_node) { create(:geo_node) }

  subject { described_class.new(project) }

  describe '#create!' do
    it_behaves_like 'a Geo event store', Geo::ResetChecksumEvent

    context 'when running on a primary node' do
      before do
        stub_primary_node
      end

      it 'tracks the project that checksum must be wiped' do
        subject.create!

        expect(Geo::ResetChecksumEvent.last).to have_attributes(project_id: project.id)
      end
    end
  end
end
