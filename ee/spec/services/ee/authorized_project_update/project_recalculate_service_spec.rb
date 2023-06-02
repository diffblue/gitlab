# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuthorizedProjectUpdate::ProjectRecalculateService, feature_category: :groups_and_projects do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  let(:worker) { Security::ScanResultPolicies::SyncProjectWorker }

  subject(:execute) { described_class.new(project).execute }

  before do
    stub_licensed_features(security_orchestration_policies: true)
  end

  context 'when project has user with higher authorization levels' do
    before do
      project.add_developer(user)
      project.project_authorizations.where(user: user).delete_all
    end

    it 'invokes SyncProjectsWorker' do
      expect(worker).to receive(:perform_in).with(1.minute, project.id)

      execute
    end
  end

  context 'when user has lower authorization levels' do
    before do
      project.add_guest(user)
    end

    it 'does not invoke SyncProjectsWorker' do
      expect(worker).not_to receive(:perform_async)

      execute
    end
  end

  context 'when project does not have security_orchestration_policies enabled' do
    before do
      stub_licensed_features(security_orchestration_policies: false)

      project.add_developer(user)
      project.project_authorizations.where(user: user).delete_all
    end

    it 'does not invoke SyncProjectsWorker' do
      expect(worker).not_to receive(:perform_in)

      execute
    end
  end
end
