# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEvents::RunnerCustomAuditEventService do
  describe '#security_event' do
    let(:logger) { instance_double(Gitlab::AuditJsonLogger) }

    let(:user) { create(:user) }
    let(:entity) { create(:project) }
    let(:target_details) { ::Gitlab::Routing.url_helpers.project_runner_path(entity, runner) }
    let(:target_id) { runner.id }
    let(:target_type) { 'Ci::Runner' }
    let(:entity_type) { 'Project' }
    let(:runner) { create(:ci_runner, :project, projects: [entity]) }
    let(:custom_message) { 'Custom Event' }
    let(:service) { described_class.new(runner, user, entity, custom_message) }

    before do
      stub_licensed_features(audit_events: true)
    end

    it 'logs the event to file' do
      expect(service).to receive(:file_logger).and_return(logger)
      expect(logger).to receive(:info).with({ author_id: user.id,
                                              author_name: user.name,
                                              entity_id: entity.id,
                                              entity_type: entity_type,
                                              custom_message: custom_message,
                                              target_details: target_details,
                                              target_id: target_id,
                                              target_type: target_type,
                                              created_at: anything })

      expect { service.security_event }.to change(AuditEvent, :count).by(1)

      security_event = AuditEvent.last

      expect(security_event.details).to eq({
        author_name: user.name,
        custom_message: custom_message,
        entity_id: entity.id,
        entity_type: entity_type,
        target_details: target_details,
        target_id: target_id,
        target_type: target_type
      })

      expect(security_event.author_id).to eq(user.id)
      expect(security_event.entity_id).to eq(entity.id)
      expect(security_event.entity_type).to eq(entity_type)
    end
  end
end
