# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnregisterRunnerService, '#execute', feature_category: :runner_fleet do
  let(:audit_service) { instance_double(::AuditEvents::UnregisterRunnerAuditEventService) }
  let(:current_user) { nil }
  let(:token) { 'abc123' }

  subject { described_class.new(runner, current_user || token).execute }

  context 'on an instance runner' do
    let(:runner) { create(:ci_runner) }

    it 'logs an audit event with the instance scope' do
      expect(audit_service).to receive(:track_event).once.and_return('track_event_return_value')
      expect(::AuditEvents::UnregisterRunnerAuditEventService).to receive(:new)
        .with(runner, token, nil)
        .once.and_return(audit_service)

      subject
    end
  end

  context 'on a group runner' do
    let(:group) { create(:group) }
    let(:runner) { create(:ci_runner, :group, groups: [group]) }
    let(:current_user) { build(:user) }

    it 'logs an audit event with the group scope' do
      expect(audit_service).to receive(:track_event).once.and_return('track_event_return_value')
      expect(::AuditEvents::UnregisterRunnerAuditEventService).to receive(:new)
        .with(runner, current_user, group)
        .once.and_return(audit_service)

      subject
    end
  end

  context 'on a project runner' do
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }
    let(:runner) { create(:ci_runner, :project, projects: [project1, project2]) }

    it 'logs an audit event per project' do
      expect(audit_service).to receive(:track_event).twice.and_return('track_event_return_value')
      expect(::AuditEvents::UnregisterRunnerAuditEventService).to receive(:new)
        .with(runner, token, project1)
        .once.and_return(audit_service)
      expect(::AuditEvents::UnregisterRunnerAuditEventService).to receive(:new)
        .with(runner, token, project2)
        .once.and_return(audit_service)

      subject
    end
  end
end
