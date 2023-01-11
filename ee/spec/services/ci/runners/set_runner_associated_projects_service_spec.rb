# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::SetRunnerAssociatedProjectsService, '#execute', feature_category: :runner_fleet do
  subject(:execute) do
    described_class.new(runner: project_runner, current_user: user, project_ids: [new_project.id]).execute
  end

  let_it_be(:owner_project) { create(:project) }
  let_it_be(:new_project) { create(:project) }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [owner_project]) }

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(project_runner).not_to receive(:assign_to)
      expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

      expect(execute).to be_error
      expect(execute.http_status).to eq :forbidden
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:user, :admin) }

    context 'with assign_to returning true' do
      it 'calls audit on Auditor and returns success response', :aggregate_failures do
        expect(project_runner).to receive(:assign_to).with(new_project, user).once.and_return(true)
        expect(::Gitlab::Audit::Auditor).to receive(:audit).with(
          a_hash_including(
            name: 'set_runner_associated_projects',
            author: user,
            scope: user,
            target: project_runner
          ))

        expect(execute).to be_success
      end
    end

    context 'with assign_to returning false' do
      it 'does not call audit on Auditor and returns error response', :aggregate_failures do
        expect(project_runner).to receive(:assign_to).with(new_project, user).once.and_return(false)
        expect(::Gitlab::Audit::Auditor).not_to receive(:audit)

        expect(execute).to be_error
      end
    end
  end
end
