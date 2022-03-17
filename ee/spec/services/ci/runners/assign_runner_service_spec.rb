# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::AssignRunnerService, '#execute' do
  let_it_be(:owner_project) { create(:project) }
  let_it_be(:new_project) { create(:project) }
  let_it_be(:project_runner) { create(:ci_runner, :project, projects: [owner_project]) }

  let(:audit_service) { instance_double(::AuditEvents::RunnerCustomAuditEventService) }

  subject { described_class.new(project_runner, new_project, user).execute }

  context 'with unauthorized user' do
    let(:user) { build(:user) }

    it 'does not call assign_to on runner and returns false', :aggregate_failures do
      expect(project_runner).not_to receive(:assign_to)
      expect(::AuditEvents::RunnerCustomAuditEventService).not_to receive(:new)

      is_expected.to be_falsey
    end
  end

  context 'with admin user', :enable_admin_mode do
    let(:user) { create_default(:admin) }

    before do
      expect(audit_service).to receive(:track_event).once.and_return('track_event_return_value')
    end

    it 'calls track_event on RunnerCustomAuditEventService and returns assign_to return value', :aggregate_failures do
      expect(project_runner).to receive(:assign_to).with(new_project, user).once.and_return('assign_to return value')
      expect(::AuditEvents::RunnerCustomAuditEventService).to receive(:new)
        .with(project_runner, user, new_project, 'Assigned CI runner to project')
        .once.and_return(audit_service)

      is_expected.to eq('assign_to return value')
    end
  end
end
