# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ProjectRepositoryReplicator, feature_category: :geo_replication do
  let(:model_record) { create(:project, :repository) }

  include_examples 'a repository replicator' do
    describe 'housekeeping implementation' do
      let_it_be(:pool_repository) { create(:pool_repository) }
      let_it_be(:model_record) { create(:project, pool_repository: pool_repository) }

      before do
        stub_current_geo_node(secondary)
      end

      it 'calls Geo::CreateObjectPoolService' do
        stub_secondary_node

        expect_next_instance_of(Geo::CreateObjectPoolService) do |service|
          expect(service).to receive(:execute)
        end

        replicator.before_housekeeping
      end
    end
  end
end
