# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnassignRunnerService, '#execute', feature_category: :runner_fleet do
  let_it_be(:owner_project) { create(:project) }
  let_it_be(:other_project) { create(:project) }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [owner_project, other_project]) }

  let(:runner_project) { project_runner.runner_projects.last }
  let(:audit_service) { instance_double(::AuditEvents::RunnerCustomAuditEventService) }

  subject(:execute) { described_class.new(runner_project, user).execute }

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(project_runner).not_to receive(:assign_to)
      expect(::AuditEvents::RunnerCustomAuditEventService).not_to receive(:new)

      is_expected.to be_error
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:admin) }

    before do
      expect(audit_service).to receive(:track_event).once.and_return('track_event_return_value')
    end

    it 'calls track_event on RunnerCustomAuditEventService and returns success response', :aggregate_failures do
      expect(runner_project).to receive(:destroy).once.and_call_original
      expect(::AuditEvents::RunnerCustomAuditEventService).to receive(:new)
        .with(project_runner, user, other_project, 'Unassigned CI runner from project')
        .once.and_return(audit_service)

      is_expected.to be_success
    end
  end
end
