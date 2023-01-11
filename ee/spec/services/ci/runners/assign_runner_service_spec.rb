# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::AssignRunnerService, '#execute', feature_category: :runner_fleet do
  let_it_be(:owner_project) { create(:project) }
  let_it_be(:new_project) { create(:project) }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [owner_project]) }

  let(:audit_service) { instance_double(::AuditEvents::RunnerCustomAuditEventService) }

  subject(:execute) { described_class.new(project_runner, new_project, user).execute }

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns error response', :aggregate_failures do
      expect(project_runner).not_to receive(:assign_to)
      expect(::AuditEvents::RunnerCustomAuditEventService).not_to receive(:new)

      expect(execute).to be_error
      expect(execute.http_status).to eq :forbidden
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:admin) }

    context 'with assign_to returning true' do
      it 'calls track_event on RunnerCustomAuditEventService and returns success response', :aggregate_failures do
        expect(audit_service).to receive(:track_event).once.and_return('track_event_return_value')
        expect(project_runner).to receive(:assign_to).with(new_project, user).once.and_return(true)
        expect(::AuditEvents::RunnerCustomAuditEventService).to receive(:new)
          .with(project_runner, user, new_project, 'Assigned CI runner to project')
          .once.and_return(audit_service)

        is_expected.to be_success
      end
    end

    context 'with assign_to returning false' do
      it 'does not call track_event on RunnerCustomAuditEventService and returns error response', :aggregate_failures do
        expect(audit_service).not_to receive(:track_event)
        expect(project_runner).to receive(:assign_to).with(new_project, user).once.and_return(false)
        expect(::AuditEvents::RunnerCustomAuditEventService).not_to receive(:new)

        is_expected.to be_error
      end
    end
  end
end
