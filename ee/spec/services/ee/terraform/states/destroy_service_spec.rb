# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Terraform::States::DestroyService, :geo, feature_category: :infrastructure_as_code do
  let_it_be(:state) { create(:terraform_state, :with_version, :deletion_in_progress) }
  let_it_be(:version) { state.versions.first }

  describe '#execute' do
    subject { described_class.new(state).execute }

    it 'creates deletion events for associated state versions' do
      expect(Geo::TerraformStateVersionReplicator)
        .to receive(:bulk_create_delete_events_async)
        .with([version.replicator.deleted_params])

      subject
    end
  end
end
