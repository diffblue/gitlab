# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::DevopsAdoption::CreateAllSnapshotsWorker, feature_category: :devops_reports do
  subject(:worker) { described_class.new }

  describe "#perform" do
    let!(:enabled_namespace1) { create :devops_adoption_enabled_namespace }
    let!(:enabled_namespace2) { create :devops_adoption_enabled_namespace }
    let!(:enabled_namespace3) do
      create(:devops_adoption_enabled_namespace).tap do |enabled_namespace|
        create(:devops_adoption_snapshot, namespace: enabled_namespace.namespace)
      end
    end

    it 'schedules workers individually for all pending enabled_namespaces' do
      freeze_time do
        expect(Analytics::DevopsAdoption::CreateSnapshotWorker).to receive(:perform_in).with(0, enabled_namespace1.id)
        expect(Analytics::DevopsAdoption::CreateSnapshotWorker).to receive(:perform_in).with(5, enabled_namespace2.id)
        expect(Analytics::DevopsAdoption::CreateSnapshotWorker).not_to receive(:perform_in).with(anything, enabled_namespace3.id)

        worker.perform
      end
    end
  end
end
