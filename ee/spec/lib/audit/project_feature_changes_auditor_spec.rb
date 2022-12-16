# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Audit::ProjectFeatureChangesAuditor, feature_category: :audit_events do
  describe '#execute' do
    let!(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, :pages_enabled, group: group, visibility_level: 0) }
    let(:features) { project.project_feature }
    let(:project_feature_changes_auditor) { described_class.new(user, features, project) }

    before do
      stub_licensed_features(extended_audit_events: true, audit_events: true, external_audit_events: true)
      group.add_owner(user)
      group.external_audit_event_destinations.create!(destination_url: 'http://example.com')
    end

    it 'creates an event when any project feature level changes', :aggregate_failures do
      columns = project.project_feature.attributes.keys.select { |attr| attr.end_with?('level') }

      columns.each do |column|
        event_name = "project_feature_#{column}_updated"
        previous_value = features.method(column).call
        new_value = if previous_value == ProjectFeature::DISABLED
                      ProjectFeature::ENABLED
                    else
                      ProjectFeature::DISABLED
                    end

        features.update_attribute(column, new_value)

        expect(AuditEvents::AuditEventStreamingWorker).to receive(:perform_async)
          .with(event_name, anything, anything)

        expect { project_feature_changes_auditor.execute }.to change(AuditEvent, :count).by(1)

        event = AuditEvent.last
        expect(event.details[:from]).to eq ::Gitlab::VisibilityLevel.level_name(previous_value)
        expect(event.details[:to]).to eq ::Gitlab::VisibilityLevel.level_name(new_value)
        expect(event.details[:change]).to eq column
      end
    end
  end
end
