# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateJobArtifactRegistryToSsf, :geo do
  let(:registry) { table(:job_artifact_registry) }

  let!(:registry1) { registry.create!(artifact_id: 1, success: true, state: 0) }
  let!(:registry2) { registry.create!(artifact_id: 2, success: true, state: 0) }
  let!(:registry3) { registry.create!(artifact_id: 3, success: true, state: 0) }

  subject do
    described_class.new.perform(registry1.id, registry3.id)
  end

  it 'updates registries' do
    subject

    expect(registry.where(state: 2).count).to eq 3
  end
end
