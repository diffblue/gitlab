# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignManagementRepositoryReplicator, feature_category: :geo_replication do
  let(:model_record) { build(:design_management_repository, project: create(:project)) }

  include_examples 'a repository replicator' do
    def handle_model_record_before_verification_integration_examples
      model_record.save!
      model_record.repository.create_if_not_exists
    end

    describe '#verify' do
      context 'when design git repository does not exist' do
        it 'creates a new git repo' do
          expect { model_record.replicator.verify }.to change {
                                                         model_record.repository.raw_repository.exists?
                                                       }.from(false).to(true)

          expect(replicator.primary_checksum).to be_present
        end
      end
    end
  end
end
