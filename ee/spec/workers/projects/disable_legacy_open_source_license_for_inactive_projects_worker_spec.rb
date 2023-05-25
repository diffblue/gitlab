# frozen_string_literal: true

require "spec_helper"

RSpec.describe Projects::DisableLegacyOpenSourceLicenseForInactiveProjectsWorker, type: :worker, feature_category: :groups_and_projects do
  describe '#perform' do
    it 'invokes Projects::DisableLegacyInactiveProjectsService' do
      service = instance_double('Projects::DisableLegacyInactiveProjectsService')
      allow(Projects::DisableLegacyInactiveProjectsService).to receive(:new) { service }

      expect(service).to receive(:execute)

      subject.perform
    end
  end
end
